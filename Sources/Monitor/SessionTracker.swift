import Foundation

// MARK: - Session Tracker (ARCH-02)
// Manages per-session state, event processing, and priority-based aggregate state resolution.

extension ClaudeMonitor {

    func processEvent(_ json: String) {
        guard let data = json.data(using: .utf8),
              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = event["event"] as? String,
              event["sid"] is String,
              event["ts"] is Int else { return }

        let sid = event["sid"] as? String ?? ""

        if !sid.isEmpty {
            sessionLastSeen[sid] = Date()
        }

        // Permission — trigger approveQuestion
        if type == "notification" && event["type"] as? String == "permission_prompt" {
            idleWork?.cancel()
            let tool = event["tool"] as? String ?? ""
            let summary = event["summary"] as? String ?? tool.lowercased()
            setupGlobalHotkeys()

            if currentPreset == .yolo {
                pendingPermission = PendingPermission(id: sid, tool: tool, summary: summary)
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    self?.respondToPermission(allow: true)
                }
            } else {
                if !sid.isEmpty { sessionStates[sid] = .approveQuestion }
                sessionCount = sessionStates.count
                if pendingPermission == nil {
                    pendingPermission = PendingPermission(id: sid, tool: tool, summary: summary)
                    awaitingUserAction = true
                    thinkingStartTime = Date()
                    state = .approveQuestion
                    playAlert()
                }
            }
            return
        }
        if type == "permission_timeout" { return }

        // Needs input
        if type == "notification" && event["type"] as? String == "needs_input" {
            idleWork?.cancel()
            if !sid.isEmpty { sessionStates[sid] = .needsInput }
            awaitingUserAction = true
            updateAggregateState()
            playAlert()
            return
        }

        // Orphan cleanup — session moved on
        if awaitingUserAction && (type == "pre_tool" || type == "post_tool" || type == "stop" || type == "stop_failure") {
            httpServer.cancelOrphanedPermission(for: sid)
            if httpServer.pendingPermissionConnections.isEmpty {
                awaitingUserAction = false
                pendingPermission = nil
                state = .idle
            } else {
                if let next = httpServer.pendingPermissionConnections.first {
                    pendingPermission = PendingPermission(id: next.sessionId, tool: "", summary: "Pending permission")
                    state = .approveQuestion
                }
            }
        }

        idleWork?.cancel()

        switch type {
        case "pre_tool", "post_tool":
            doneDebounceWork?.cancel()  // Cancel pending DONE transition (DONE-DEBOUNCE)
            let tool = event["tool"] as? String
            if let tool { currentTool = tool }
            if sessionStates[sid] != .working {
                thinkingStartTime = Date()
            }
            if !sid.isEmpty { sessionStates[sid] = .working }
            if ttsService.isSpeaking {
                ttsService.stopSpeaking()
            }
            updateAggregateState()
        case "stop":
            if !sid.isEmpty { sessionStates[sid] = .done }
            thinkingStartTime = nil
            currentTool = nil
            // Debounce DONE: wait before showing DONE to avoid false flashes from
            // subagent stops or brief gaps between turns (DONE-DEBOUNCE).
            doneDebounceWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.updateAggregateState()
                    if self.state == .done {
                        if self.currentPreset != .yolo { self.playDoneChime() }
                        self.startIdleTimer(interval: 180)
                    }
                }
            }
            doneDebounceWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
        case "stop_failure":
            if !sid.isEmpty { sessionStates[sid] = .error }
            thinkingStartTime = nil
            currentTool = nil
            updateAggregateState()
            // Auto-recover from error after 30s so the widget doesn't stay stuck (AUDIT-FIX).
            if state == .error { startIdleTimer(interval: 30) }
        case "session_start":
            if !sid.isEmpty { sessionStates[sid] = .working }
            updateAggregateState()
        case "session_end":
            if !sid.isEmpty { sessionStates.removeValue(forKey: sid) }
            lastPruneTime = .distantPast
            updateAggregateState()
        default:
            break
        }
    }

    /// Derive the overall state from all active sessions using priority-based resolution.
    func updateAggregateState() {
        // Prune sessions not seen for 2 hours
        if Date().timeIntervalSince(lastPruneTime) > 30 {
            let cutoff = Date().addingTimeInterval(-7200)
            for (sid, lastSeen) in sessionLastSeen where lastSeen < cutoff {
                sessionStates.removeValue(forKey: sid)
                sessionLastSeen.removeValue(forKey: sid)
            }
            lastPruneTime = Date()
        }

        if awaitingUserAction && pendingPermission != nil {
            state = .approveQuestion
            return
        }

        let values = Array(sessionStates.values)
        if values.isEmpty {
            sessionCount = 0
            return
        }

        let highest = values.max(by: { $0.priority < $1.priority }) ?? .idle
        if highest.priority >= state.priority || state == .done || state == .idle {
            let oldState = state
            state = highest
            if state == .idle && oldState != .idle {
                idleStartTime = Date()
            }
            if state != .idle {
                idleStartTime = nil
            }
        }
        sessionCount = sessionStates.count
    }
}
