import Foundation
import Network

// MARK: - HTTPHookServer

/// NWListener-based HTTP server that accepts POST /hook requests from Claude Code hooks.
///
/// Lifecycle:
/// - `start(handler:)` — binds to a port in 19222-19230 (or OS-assigned) and writes port file
/// - `stop()` — cancels listener and deletes port file
///
/// Port file at `~/.claude/cc-beeper/port` enables instance detection and allows hook commands
/// to read the active port dynamically.
@MainActor
final class HTTPHookServer {

    // MARK: - Types

    /// Handler called when a valid POST /hook request arrives.
    /// - Returns nil for async hooks (immediate 200 OK sent).
    /// - Returns a dict for blocking hooks (response deferred; caller must call sendPermissionResponse).
    typealias HookHandler = @MainActor (_ payload: [String: Any]) -> [String: Any]?

    // MARK: - Constants

    static let portFile = NSHomeDirectory() + "/.claude/cc-beeper/port"
    static let tokenFile = NSHomeDirectory() + "/.claude/cc-beeper/token"
    private static let portRange: [UInt16] = Array(19222...19230)

    // MARK: - State

    private var listener: NWListener?
    private var handler: HookHandler?
    private(set) var activePort: UInt16 = 0
    private(set) var bearerToken: String = ""

    /// Per-connection receive buffers, keyed by ObjectIdentifier of the NWConnection.
    private var connectionBuffers: [ObjectIdentifier: Data] = [:]

    /// Ordered array of pending permission connections, keyed by session ID (AUDIT-04).
    /// FIFO ordering: oldest request first. Array preserves insertion order (dictionaries do not).
    private(set) var pendingPermissionConnections: [(sessionId: String, connection: NWConnection)] = []

    // MARK: - Public API

    /// Start the HTTP server. Tries ports 19222-19230, falls back to OS-assigned port.
    /// Generates a cryptographic bearer token and writes it to the token file (SEC-01, SEC-02).
    func start(handler: @escaping HookHandler) {
        self.handler = handler
        generateAndWriteToken()
        startListener(portIndex: 0)
    }

    /// Stop the HTTP server and remove the port file and token file.
    func stop() {
        listener?.cancel()
        listener = nil
        removePort()
        removeToken()
        activePort = 0
    }

    // MARK: - Token Management (SEC-01, SEC-02)

    /// Generate a cryptographically random bearer token and write it to the token file.
    private func generateAndWriteToken() {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        bearerToken = bytes.map { String(format: "%02x", $0) }.joined()

        let fm = FileManager.default
        let dir = (Self.tokenFile as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

        // Write atomically with 0o600 permissions
        let tmp = Self.tokenFile + ".tmp"
        do {
            try bearerToken.write(toFile: tmp, atomically: false, encoding: .utf8)
            try? fm.removeItem(atPath: Self.tokenFile)
            try fm.moveItem(atPath: tmp, toPath: Self.tokenFile)
            try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: Self.tokenFile)
        } catch {
            portWriteError = "Failed to write token file: \(error.localizedDescription)"
        }
    }

    /// Remove the token file.
    private func removeToken() {
        try? FileManager.default.removeItem(atPath: Self.tokenFile)
    }

    /// Send a permission response to the deferred HTTP connection for a specific session (AUDIT-04).
    /// Returns true if more pending connections remain (so caller can surface the next one).
    @discardableResult
    func sendPermissionResponse(_ payload: [String: Any], for sessionId: String) -> Bool {
        guard let index = pendingPermissionConnections.firstIndex(where: { $0.sessionId == sessionId }) else { return false }
        let connection = pendingPermissionConnections.remove(at: index).connection
        if let body = try? JSONSerialization.data(withJSONObject: payload) {
            sendResponse(200, body: body, on: connection)
        } else {
            sendResponse(200, body: Data(), on: connection)
        }
        return !pendingPermissionConnections.isEmpty
    }

    /// Cancel and deny all orphaned permission connections for a session that moved on.
    func cancelOrphanedPermission(for sessionId: String) {
        let denyPayload: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "PermissionRequest",
                "decision": ["behavior": "deny", "message": "Session moved on"]
            ]
        ]
        pendingPermissionConnections.removeAll { entry in
            if entry.sessionId == sessionId {
                if let body = try? JSONSerialization.data(withJSONObject: denyPayload) {
                    sendResponse(200, body: body, on: entry.connection)
                } else {
                    entry.connection.cancel()
                }
                return true
            }
            return false
        }
    }

    // MARK: - Instance Detection

    /// Check whether another CC-Beeper instance is listening on the given port.
    /// Performs a synchronous HTTP GET with a 2-second timeout.
    static func isPortResponding(_ port: UInt16) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var isAlive = false
        let url = URL(string: "http://127.0.0.1:\(port)/hook")!
        var request = URLRequest(url: url, timeoutInterval: 2.0)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { _, response, _ in
            isAlive = (response as? HTTPURLResponse) != nil
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .now() + 3.0)
        return isAlive
    }

    // MARK: - Port File

    /// Read the port number from the port file. Returns nil if the file doesn't exist or is invalid.
    static func readPort() -> UInt16? {
        guard let data = FileManager.default.contents(atPath: portFile),
              let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let port = UInt16(str) else { return nil }
        return port
    }

    /// Write the active port number atomically to the port file (FRAG-03: surface failures).
    func writePort(_ port: UInt16) {
        let dir = (Self.portFile as NSString).deletingLastPathComponent
        do {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        } catch {
            portWriteError = "Failed to create IPC directory: \(error.localizedDescription)"
            return
        }

        let tmp = Self.portFile + ".tmp"
        let content = "\(port)"
        do {
            try content.write(toFile: tmp, atomically: false, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: Self.portFile)
            try FileManager.default.moveItem(atPath: tmp, toPath: Self.portFile)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: Self.portFile)
            portWriteError = nil
        } catch {
            portWriteError = "Failed to write port file: \(error.localizedDescription)"
        }
    }

    /// Last port write error, if any (FRAG-03). Nil means success.
    private(set) var portWriteError: String?

    /// Last listener error, if any (FRAG-04). Nil means success.
    private(set) var listenerError: String?

    /// Remove the port file if it exists.
    func removePort() {
        try? FileManager.default.removeItem(atPath: Self.portFile)
    }

    // MARK: - Private: Listener Lifecycle

    private func startListener(portIndex: Int) {
        let ports = Self.portRange
        let portToTry: NWEndpoint.Port

        if portIndex < ports.count {
            portToTry = NWEndpoint.Port(rawValue: ports[portIndex])!
        } else {
            // Exhausted range — let OS assign
            portToTry = NWEndpoint.Port(rawValue: 0)!
        }

        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host("127.0.0.1"),
            port: portToTry
        )

        guard let newListener = try? NWListener(using: params) else {
            listenerError = "Failed to create NWListener on port \(portToTry.rawValue)"
            return
        }

        newListener.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch state {
                case .ready:
                    let boundPort = newListener.port?.rawValue ?? 0
                    self.activePort = boundPort
                    self.listenerError = nil
                    self.writePort(boundPort)
                case .failed(let error):
                    // Check for port-in-use error — try next port
                    if case .posix(let posixError) = error, posixError == .EADDRINUSE {
                        newListener.cancel()
                        self.startListener(portIndex: portIndex + 1)
                    } else {
                        // Other failure — try next port anyway
                        newListener.cancel()
                        self.startListener(portIndex: portIndex + 1)
                    }
                case .cancelled:
                    self.removePort()
                default:
                    break
                }
            }
        }

        newListener.newConnectionHandler = { [weak self] connection in
            Task { @MainActor [weak self] in
                guard let self else { return }
                connection.start(queue: .main)
                self.receive(on: connection)
            }
        }

        newListener.start(queue: .main)
        self.listener = newListener
    }

    // MARK: - Private: HTTP Parsing

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let data, !data.isEmpty else {
                    if !isComplete { self.receive(on: connection) }
                    return
                }
                let key = ObjectIdentifier(connection)
                var buffer = self.connectionBuffers[key] ?? Data()
                buffer.append(data)
                self.connectionBuffers[key] = buffer
                self.processBuffer(for: connection)
            }
        }
    }

    private func processBuffer(for connection: NWConnection) {
        let key = ObjectIdentifier(connection)
        guard let buffer = connectionBuffers[key] else { return }

        // Find \r\n\r\n header terminator
        guard let headerRange = findHeaderEnd(in: buffer) else {
            // Need more data
            receive(on: connection)
            return
        }

        let headerData = buffer[..<headerRange.lowerBound]
        guard let headerStr = String(data: headerData, encoding: .utf8) else {
            connectionBuffers.removeValue(forKey: key)
            sendResponse(400, body: Data(), on: connection)
            return
        }

        // Validate method and path from request line
        let requestLine = headerStr.components(separatedBy: "\r\n").first ?? ""
        guard requestLine.hasPrefix("POST") || requestLine.hasPrefix("GET") ||
              requestLine.hasPrefix("HEAD") || requestLine.hasPrefix("DELETE") ||
              requestLine.hasPrefix("PUT") || requestLine.hasPrefix("OPTIONS") else {
            connectionBuffers.removeValue(forKey: key)
            sendResponse(400, body: Data(), on: connection)
            return
        }

        if !requestLine.hasPrefix("POST") {
            connectionBuffers.removeValue(forKey: key)
            sendResponse(405, body: Data(), on: connection)
            return
        }

        if !requestLine.contains("/hook") {
            connectionBuffers.removeValue(forKey: key)
            sendResponse(404, body: Data(), on: connection)
            return
        }

        // Parse Content-Length
        let bodyStart = headerRange.upperBound
        let contentLength = parseContentLength(from: headerStr) ?? 0

        guard buffer.count >= bodyStart + contentLength else {
            // Need more data
            receive(on: connection)
            return
        }

        // Validate bearer token (SEC-03)
        if !bearerToken.isEmpty {
            let authHeader = parseHeader("authorization", from: headerStr)
            let expectedPrefix = "Bearer "
            if !authHeader.hasPrefix(expectedPrefix) || String(authHeader.dropFirst(expectedPrefix.count)) != bearerToken {
                connectionBuffers.removeValue(forKey: key)
                sendResponse(401, body: Data(), on: connection)
                return
            }
        }

        let bodyData = buffer[bodyStart ..< bodyStart + contentLength]
        connectionBuffers.removeValue(forKey: key)
        handleBody(bodyData, connection: connection)
    }

    private func findHeaderEnd(in data: Data) -> Range<Data.Index>? {
        let terminator = Data([0x0D, 0x0A, 0x0D, 0x0A]) // \r\n\r\n
        guard let range = data.range(of: terminator) else { return nil }
        return range
    }

    private func parseContentLength(from headerStr: String) -> Int? {
        guard let value = parseHeader("content-length", from: headerStr) as String?,
              !value.isEmpty else { return nil }
        return Int(value)
    }

    /// Parse an HTTP header value by name (case-insensitive).
    private func parseHeader(_ name: String, from headerStr: String) -> String {
        let target = name.lowercased() + ":"
        for line in headerStr.components(separatedBy: "\r\n") {
            if line.lowercased().hasPrefix(target) {
                return String(line.dropFirst(target.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        return ""
    }

    private func handleBody(_ bodyData: Data, connection: NWConnection) {
        guard !bodyData.isEmpty else {
            sendResponse(200, body: Data(), on: connection)
            return
        }

        guard let payload = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] else {
            sendResponse(400, body: Data(), on: connection)
            return
        }

        // Call handler — nil means async (send 200 now), non-nil means blocking (defer response)
        let result = handler?(payload)

        if let result {
            // Check if handler wants to send immediately (auto-approve in YOLO/preset)
            let sendNow = result["_send_immediately"] as? Bool ?? false

            if sendNow {
                // Auto-approve: strip marker and send response right away
                var cleaned = result
                cleaned.removeValue(forKey: "_send_immediately")
                if let body = try? JSONSerialization.data(withJSONObject: cleaned) {
                    sendResponse(200, body: body, on: connection)
                } else {
                    sendResponse(200, body: Data(), on: connection)
                }
            } else {
                // Blocking hook: check if it's a permission prompt that needs deferred response
                let eventName = payload["hook_event_name"] as? String ?? ""
                let notifType = payload["notification_type"] as? String ?? ""
                let isPermissionPrompt = (eventName == "Notification" && notifType == "permission_prompt")
                    || eventName == "PermissionRequest"

                if isPermissionPrompt {
                    let sessionId = (payload["session_id"] as? String) ?? ""
                    pendingPermissionConnections.append((sessionId: sessionId, connection: connection))
                    // Do NOT send response yet — waiting for user to approve/deny
                } else {
                    if let body = try? JSONSerialization.data(withJSONObject: result) {
                        sendResponse(200, body: body, on: connection)
                    } else {
                        sendResponse(200, body: Data(), on: connection)
                    }
                }
            }
        } else {
            // Async hook — send 200 immediately
            sendResponse(200, body: Data(), on: connection)
        }
    }

    // MARK: - Private: HTTP Response

    private func sendResponse(_ statusCode: Int, body: Data, on connection: NWConnection) {
        let statusText: String
        switch statusCode {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 401: statusText = "Unauthorized"
        case 404: statusText = "Not Found"
        case 405: statusText = "Method Not Allowed"
        default: statusText = "Error"
        }
        var response = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
        response += "Content-Length: \(body.count)\r\n"
        response += "Connection: close\r\n"
        response += "\r\n"
        var responseData = Data(response.utf8)
        responseData.append(body)
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
