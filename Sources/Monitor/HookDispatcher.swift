import Foundation

// MARK: - Hook Dispatcher (ARCH-01)
// Translates HTTP hook payloads into synthetic JSONL events and routes them to processEvent().

extension ClaudeMonitor {

    /// Translates HTTP hook payloads into the existing JSONL event format
    /// and routes to processEvent(). Returns nil for async hooks.
    /// For permission_prompt Notifications, returns a sentinel (handled by HTTPHookServer).
    func handleHookPayload(_ payload: [String: Any]) -> [String: Any]? {
        guard let hookEventName = payload["hook_event_name"] as? String else { return nil }
        let sessionId = payload["session_id"] as? String ?? ""
        let toolName = payload["tool_name"] as? String
        let ts = Int(Date().timeIntervalSince1970)

        // Translate hook_event_name to existing event types
        let eventType: String
        switch hookEventName {
        case "UserPromptSubmit":
            eventType = "pre_tool"  // Reuse working-state transition (AUDIT-03)
        case "PreToolUse":
            eventType = "pre_tool"
        case "PostToolUse":
            eventType = "post_tool"
        case "Notification":
            return handleNotification(payload, sessionId: sessionId, toolName: toolName, ts: ts)

        case "Stop":
            eventType = "stop"
            handleStopPayload(payload, sessionId: sessionId)

        case "StopFailure":
            eventType = "stop_failure"
            if let msg = payload["message"] as? String, !msg.isEmpty {
                errorDetail = String(msg.prefix(30))
            } else {
                errorDetail = "Unknown error"
            }

        case "PermissionRequest":
            return handlePermissionRequest(payload, sessionId: sessionId, toolName: toolName, ts: ts)

        default:
            return nil
        }

        // Build synthetic JSONL event matching existing processEvent format
        var syntheticEvent: [String: Any] = [
            "event": eventType,
            "sid": sessionId,
            "ts": ts,
        ]
        if let tool = toolName {
            syntheticEvent["tool"] = tool
        }

        if let json = try? JSONSerialization.data(withJSONObject: syntheticEvent),
           let jsonStr = String(data: json, encoding: .utf8) {
            processEvent(jsonStr)
        }

        return nil // Async — respond immediately with 200
    }

    // MARK: - Notification Sub-handler

    private func handleNotification(_ payload: [String: Any], sessionId: String, toolName: String?, ts: Int) -> [String: Any]? {
        let notificationType = payload["notification_type"] as? String ?? ""
        let message = payload["message"] as? String ?? ""

        switch notificationType {
        case "permission_prompt":
            let mode = readPermissionMode()
            let promptTool = toolName ?? payload["title"] as? String ?? ""
            let isAutoApproved = mode == .bypass ||
                (currentPreset.allowedTools?.contains(promptTool) == true)
            if isAutoApproved {
                return Self.autoApproveResponse
            }
            var syntheticEvent: [String: Any] = [
                "event": "notification",
                "type": "permission_prompt",
                "sid": sessionId,
                "ts": ts,
            ]
            if let msg = payload["message"] as? String {
                syntheticEvent["summary"] = msg
                if let tool = toolName {
                    syntheticEvent["tool"] = tool
                } else if let title = payload["title"] as? String {
                    syntheticEvent["tool"] = title
                }
            }
            let json = (try? JSONSerialization.data(withJSONObject: syntheticEvent))
                .flatMap { String(data: $0, encoding: .utf8) } ?? ""
            processEvent(json)
            return ["_hold_connection": true]

        case "question", "gsd", "discuss", "multiple_choice", "wcv", "elicitation_dialog":
            inputMessage = String(message.prefix(30))
            let syntheticEvent: [String: Any] = [
                "event": "notification",
                "type": "needs_input",
                "sid": sessionId,
                "ts": ts,
                "message": message,
            ]
            if let json = try? JSONSerialization.data(withJSONObject: syntheticEvent),
               let jsonStr = String(data: json, encoding: .utf8) {
                processEvent(jsonStr)
            }
            return nil

        case "auth_success", "auth_error":
            let flashText = notificationType == "auth_success" ? "AUTH OK" : "AUTH FAIL"
            authFlashMessage = flashText
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.authFlashMessage = nil
            }
            return nil

        case "idle_prompt":
            let syntheticEvent: [String: Any] = [
                "event": "stop",
                "sid": sessionId,
                "ts": ts,
            ]
            if let json = try? JSONSerialization.data(withJSONObject: syntheticEvent),
               let jsonStr = String(data: json, encoding: .utf8) {
                processEvent(jsonStr)
            }
            return nil

        default:
            inputMessage = String(message.prefix(30))
            let syntheticEvent: [String: Any] = [
                "event": "notification",
                "type": "needs_input",
                "sid": sessionId,
                "ts": ts,
                "message": message,
            ]
            if let json = try? JSONSerialization.data(withJSONObject: syntheticEvent),
               let jsonStr = String(data: json, encoding: .utf8) {
                processEvent(jsonStr)
            }
            return nil
        }
    }

    // MARK: - Stop Sub-handler

    private func handleStopPayload(_ payload: [String: Any], sessionId: String) {
        if let summary = payload["last_assistant_message"] as? String, !summary.isEmpty {
            lastSummary = summary
            if voiceOver && !isRecording {
                Task { [weak self] in
                    guard let self else { return }
                    _ = await self.ttsService.speakSummary(summary, provider: self.ttsProvider)
                }
            }
        } else {
            let logPath = Self.ipcDir + "/voice.log"
            let logEntry = "[\(ISO8601DateFormatter().string(from: Date()))] Stop event missing last_assistant_message for session \(sessionId)\n"
            if let logData = logEntry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logPath) {
                    if let fh = FileHandle(forWritingAtPath: logPath) {
                        fh.seekToEndOfFile()
                        fh.write(logData)
                        try? fh.close()
                    }
                } else {
                    try? logData.write(to: URL(fileURLWithPath: logPath))
                }
            }
        }
    }

    // MARK: - PermissionRequest Sub-handler

    private func handlePermissionRequest(_ payload: [String: Any], sessionId: String, toolName: String?, ts: Int) -> [String: Any]? {
        let tool = toolName ?? ""
        if tool == "AskUserQuestion" {
            let message = payload["message"] as? String ?? payload["description"] as? String ?? ""
            inputMessage = String(message.prefix(30))
            let syntheticEvent: [String: Any] = [
                "event": "notification",
                "type": "needs_input",
                "sid": sessionId,
                "ts": ts,
                "message": message,
            ]
            if let json = try? JSONSerialization.data(withJSONObject: syntheticEvent),
               let jsonStr = String(data: json, encoding: .utf8) {
                processEvent(jsonStr)
            }
            return ["_hold_connection": true]
        }
        let mode = readPermissionMode()
        let isAutoApproved = mode == .bypass ||
            (currentPreset.allowedTools?.contains(tool) == true)
        if isAutoApproved {
            return Self.autoApproveResponse
        }
        var permSyntheticEvent: [String: Any] = [
            "event": "notification",
            "type": "permission_prompt",
            "sid": sessionId,
            "ts": ts,
        ]
        if !tool.isEmpty {
            permSyntheticEvent["tool"] = tool
        }
        if let msg = payload["message"] as? String ?? payload["description"] as? String {
            permSyntheticEvent["summary"] = msg
        }
        let permJson = (try? JSONSerialization.data(withJSONObject: permSyntheticEvent))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        processEvent(permJson)
        return ["_hold_connection": true]
    }
}
