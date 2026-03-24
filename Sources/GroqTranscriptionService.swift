import Foundation

/// Groq Whisper API client for transcribing WAV audio files.
/// Uses the whisper-large-v3-turbo model via multipart form-data upload.
/// Note: Groq requires lowercase "bearer" in the Authorization header (unlike OpenAI's "Bearer").
enum GroqTranscriptionService {

    private static let endpoint = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!
    private static let model = "whisper-large-v3-turbo"

    // MARK: - Transcription

    /// Transcribe a WAV file using Groq Whisper.
    /// Deletes the temp WAV file after a successful upload.
    /// - Parameters:
    ///   - wavURL: URL of the WAV file to transcribe.
    ///   - apiKey: Groq API key (stored in Keychain via KeychainService).
    /// - Returns: Transcribed text string.
    /// - Throws: URLError or a descriptive GroqError on HTTP failure.
    static func transcribe(wavURL: URL, apiKey: String) async throws -> String {
        let audioData = try Data(contentsOf: wavURL)

        let boundary = UUID().uuidString
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        // Groq requires lowercase "bearer" — NOT "Bearer" — or the request returns 401
        request.setValue("bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipartBody(audioData: audioData, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw GroqError.httpError(statusCode: httpResponse.statusCode, body: body)
        }

        struct TranscriptionResponse: Decodable {
            let text: String
        }
        let transcription = try JSONDecoder().decode(TranscriptionResponse.self, from: data)

        // Clean up temp file after successful upload
        try? FileManager.default.removeItem(at: wavURL)

        return transcription.text
    }

    // MARK: - Multipart Body

    private static func buildMultipartBody(audioData: Data, boundary: String) -> Data {
        var body = Data()

        // Model field
        body.append("--\(boundary)\r\n".utf8Data)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".utf8Data)
        body.append("\(model)\r\n".utf8Data)

        // File field
        body.append("--\(boundary)\r\n".utf8Data)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"voice.wav\"\r\n".utf8Data)
        body.append("Content-Type: audio/wav\r\n\r\n".utf8Data)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".utf8Data)

        return body
    }

    // MARK: - Error Types

    enum GroqError: LocalizedError {
        case httpError(statusCode: Int, body: String)

        var errorDescription: String? {
            switch self {
            case .httpError(let code, let body):
                return "Groq API error \(code): \(body)"
            }
        }
    }
}

// MARK: - String Extension

private extension String {
    var utf8Data: Data {
        data(using: .utf8) ?? Data()
    }
}
