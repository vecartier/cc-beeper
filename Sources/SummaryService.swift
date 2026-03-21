import Foundation

enum SummaryService {

    private static let systemPrompt = "You are a concise assistant. Summarize this coding session's activity log into 2-3 short sentences. Focus on what was accomplished, not individual tool calls. Keep it casual and brief."

    // MARK: - Core API Methods

    static func generateSummary(
        activities: [ActivityEntry],
        provider: APIProvider,
        apiKey: String
    ) async -> String? {
        let formattedActivities = activities
            .map { "[\($0.tool)] \($0.summary)" }
            .joined(separator: "\n")

        switch provider {
        case .anthropic:
            return await callAnthropic(activities: formattedActivities, apiKey: apiKey)
        case .openAI:
            return await callOpenAI(activities: formattedActivities, apiKey: apiKey)
        }
    }

    // MARK: - Convenience

    /// Generates a summary using the first configured API key found (Anthropic preferred, then OpenAI).
    /// Returns nil immediately if no key is configured — no network call, no error.
    static func summarizeIfConfigured(activities: [ActivityEntry]) async -> String? {
        // Try Anthropic first
        if let anthropicKey = KeychainHelper.load(key: APIProvider.anthropic.keychainKey),
           !anthropicKey.isEmpty {
            print("[SummaryService] Using Anthropic key (\(anthropicKey.prefix(8))...) for \(activities.count) activities")
            return await generateSummary(activities: activities, provider: .anthropic, apiKey: anthropicKey)
        }

        // Fall back to OpenAI
        if let openAIKey = KeychainHelper.load(key: APIProvider.openAI.keychainKey),
           !openAIKey.isEmpty {
            print("[SummaryService] Using OpenAI key (\(openAIKey.prefix(8))...) for \(activities.count) activities")
            return await generateSummary(activities: activities, provider: .openAI, apiKey: openAIKey)
        }

        // No key configured — return nil silently
        print("[SummaryService] No API key found in Keychain")
        return nil
    }

    // MARK: - Private API Callers

    private static func callAnthropic(activities: String, apiKey: String) async -> String? {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let userContent = "\(systemPrompt)\n\n\(activities)"
        let body: [String: Any] = [
            "model": "claude-haiku-4-5",
            "max_tokens": 200,
            "messages": [["role": "user", "content": userContent]]
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("[SummaryService] Anthropic failed: HTTP \(code)")
                if let body = String(data: data, encoding: .utf8) { print("[SummaryService] \(body)") }
                return nil
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let contentArray = json["content"] as? [[String: Any]],
                  let firstContent = contentArray.first,
                  let text = firstContent["text"] as? String else {
                return nil
            }
            return text
        } catch {
            return nil
        }
    }

    private static func callOpenAI(activities: String, apiKey: String) async -> String? {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return nil }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": 200,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": activities]
            ]
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("[SummaryService] OpenAI failed: HTTP \(code)")
                if let body = String(data: data, encoding: .utf8) { print("[SummaryService] \(body)") }
                return nil
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return nil
            }
            return content
        } catch {
            return nil
        }
    }
}
