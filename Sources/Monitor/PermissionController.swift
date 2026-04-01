import Foundation

// MARK: - Permission Types

/// Reflects `permissions.defaultMode` in ~/.claude/settings.json.
enum PermissionMode: Equatable {
    case cautious   // "default" or field missing
    case guided     // "plan"
    case bypass     // "bypass" (covers both Guarded YOLO and Full YOLO)
}

func readPermissionMode() -> PermissionMode {
    let path = NSHomeDirectory() + "/.claude/settings.json"
    guard let data = FileManager.default.contents(atPath: path),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return .cautious
    }
    if let perms = json["permissions"] as? [String: Any],
       let mode = perms["defaultMode"] as? String {
        switch mode {
        case "plan": return .guided
        case "bypassPermissions": return .bypass
        default: return .cautious
        }
    }
    if let mode = json["permission_mode"] as? String {
        switch mode {
        case "plan": return .guided
        case "bypass": return .bypass
        default: break
        }
    }
    return .cautious
}

struct PendingPermission: Equatable {
    let id: String
    let tool: String
    let summary: String
}

// MARK: - Permission Controller (ARCH-03)

extension ClaudeMonitor {

    func respondToPermission(allow: Bool) {
        guard let permission = pendingPermission else { return }
        let decision: [String: Any] = allow
            ? ["behavior": "allow"]
            : ["behavior": "deny", "message": "Denied via CC-Beeper"]
        let response: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "PermissionRequest",
                "decision": decision
            ]
        ]
        let hasMore = httpServer.sendPermissionResponse(response, for: permission.id)

        pendingPermission = nil
        awaitingUserAction = false

        if hasMore {
            if let next = httpServer.pendingPermissionConnections.first {
                pendingPermission = PendingPermission(id: next.sessionId, tool: "", summary: "Pending permission")
                awaitingUserAction = true
                state = .approveQuestion
            }
        } else {
            // Let aggregate state resolve from all active sessions rather than
            // hardcoding — prevents hiding other working sessions (AUDIT-FIX).
            updateAggregateState()
        }
    }
}
