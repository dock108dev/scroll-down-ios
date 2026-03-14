//
//  AuthService.swift
//  ScrollDown
//
//  API client for authentication endpoints.
//  Manages JWT token storage in Keychain.
//

import Foundation
import Security

actor AuthService {
    static let shared = AuthService()

    private let session: URLSession
    private let decoder: JSONDecoder

    private static let keychainKey = "com.scrolldown.authToken"

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    enum AuthError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case decodingError(Error)
        case serverError(Int, String?)
        case unauthorized
        case noToken

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .networkError(let e): return "Network error: \(e.localizedDescription)"
            case .invalidResponse: return "Invalid response"
            case .decodingError(let e): return "Decode error: \(e.localizedDescription)"
            case .serverError(_, let msg): return msg ?? "Server error"
            case .unauthorized: return "Invalid email or password"
            case .noToken: return "Not logged in"
            }
        }
    }

    // MARK: - Auth Endpoints

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await post(path: "/auth/login", body: body, authenticated: false)
        saveToken(response.accessToken)
        return response
    }

    func signup(email: String, password: String, name: String?) async throws -> AuthResponse {
        let body = SignupRequest(email: email, password: password, name: name)
        let response: AuthResponse = try await post(path: "/auth/signup", body: body, authenticated: false)
        saveToken(response.accessToken)
        return response
    }

    func fetchProfile() async throws -> UserProfile {
        try await get(path: "/auth/me")
    }

    func changePassword(current: String, new: String) async throws -> MessageResponse {
        let body = ChangePasswordRequest(currentPassword: current, newPassword: new)
        return try await post(path: "/auth/me/password", body: body)
    }

    func changeEmail(email: String, password: String) async throws -> MessageResponse {
        let body = ChangeEmailRequest(email: email, password: password)
        return try await post(path: "/auth/me/email", body: body)
    }

    func forgotPassword(email: String) async throws -> MessageResponse {
        let body = ForgotPasswordRequest(email: email)
        return try await post(path: "/auth/forgot-password", body: body, authenticated: false)
    }

    func resetPassword(token: String, password: String) async throws -> MessageResponse {
        let body = ResetPasswordRequest(token: token, password: password)
        return try await post(path: "/auth/reset-password", body: body, authenticated: false)
    }

    func deleteAccount() async throws -> MessageResponse {
        try await delete(path: "/auth/me")
    }

    func logout() {
        deleteToken()
    }

    // MARK: - Token Management

    var hasToken: Bool {
        loadToken() != nil
    }

    func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Self.keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func saveToken(_ token: String) {
        deleteToken()
        guard let data = token.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Self.keychainKey,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Self.keychainKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - HTTP Helpers

    private func get<T: Decodable>(path: String) async throws -> T {
        let baseURL = AppConfig.shared.apiBaseURL
        guard let url = URL(string: path, relativeTo: baseURL) else { throw AuthError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try applyAuth(&request)

        return try await execute(request)
    }

    private func post<B: Encodable, T: Decodable>(
        path: String, body: B, authenticated: Bool = true
    ) async throws -> T {
        let baseURL = AppConfig.shared.apiBaseURL
        guard let url = URL(string: path, relativeTo: baseURL) else { throw AuthError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authenticated { try applyAuth(&request) }

        request.httpBody = try JSONEncoder().encode(body)
        return try await execute(request)
    }

    private func delete<T: Decodable>(path: String) async throws -> T {
        let baseURL = AppConfig.shared.apiBaseURL
        guard let url = URL(string: path, relativeTo: baseURL) else { throw AuthError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try applyAuth(&request)

        return try await execute(request)
    }

    private func applyAuth(_ request: inout URLRequest) throws {
        guard let token = loadToken() else { throw AuthError.noToken }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AuthError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }

        if http.statusCode == 401 { throw AuthError.unauthorized }

        guard (200...299).contains(http.statusCode) else {
            let msg = try? decoder.decode(MessageResponse.self, from: data)
            throw AuthError.serverError(http.statusCode, msg?.message)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AuthError.decodingError(error)
        }
    }
}
