import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case serverError(Int, String)
    case decodingError(Error)
    case networkError(Error)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired. Please log in again."
        case .serverError(let code, let msg):
            return "Server error (\(code)): \(msg)"
        case .decodingError(let err):
            return "Data error: \(err.localizedDescription)"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

final class APIClient: Sendable {
    let baseURL: URL
    private let session: URLSession
    private let tokenProvider: @Sendable () -> String?

    init(baseURL: URL, tokenProvider: @escaping @Sendable () -> String?) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func post<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        body: RequestBody
    ) async throws -> ResponseBody {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = tokenProvider() {
            request.setValue(token, forHTTPHeaderField: "X-FUNCTOR-API-TOKEN")
        }

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, body)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ResponseBody.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func post<ResponseBody: Decodable>(path: String) async throws -> ResponseBody {
        return try await post(path: path, body: EmptyBody())
    }
}

private struct EmptyBody: Codable {}
