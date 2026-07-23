import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(Int)
}

class NetworkClient {
    private let baseURL: String
    private var token: String?
    private let session: URLSession

    init(baseURL: String) {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    func setToken(_ token: String) {
        self.token = token
    }

    func clearToken() {
        self.token = nil
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \\(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return decoded
            } catch {
                throw NetworkError.decodingError
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }

    func get<T: Decodable>(endpoint: String) async throws -> T {
        return try await request(endpoint: endpoint, method: .get)
    }

    func post<T: Decodable>(endpoint: String, body: Encodable) async throws -> T {
        return try await request(endpoint: endpoint, method: .post, body: body)
    }

    func put<T: Decodable>(endpoint: String, body: Encodable) async throws -> T {
        return try await request(endpoint: endpoint, method: .put, body: body)
    }

    func delete(endpoint: String) async throws {
        let _: EmptyResponse = try await request(endpoint: endpoint, method: .delete)
    }
}

struct EmptyResponse: Decodable {}
