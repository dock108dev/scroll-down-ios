//
//  AuthModels.swift
//  ScrollDown
//
//  User authentication models matching the backend API.
//

import Foundation

// MARK: - User Role

enum UserRole: String, Codable, CaseIterable {
    case guest
    case user
    case admin

    var displayName: String {
        switch self {
        case .guest: return "Guest"
        case .user: return "User"
        case .admin: return "Admin"
        }
    }

    var isAdmin: Bool { self == .admin }
    var isAuthenticated: Bool { self != .guest }
}

// MARK: - Auth Requests

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let email: String
    let password: String
    let name: String?
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let token: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case token, password
    }
}

struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
    }
}

struct ChangeEmailRequest: Codable {
    let email: String
    let password: String
}

// MARK: - Auth Responses

struct AuthResponse: Codable {
    let accessToken: String
    let role: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case role
    }

    var userRole: UserRole {
        UserRole(rawValue: role) ?? .user
    }
}

struct UserProfile: Codable {
    let email: String
    let role: String
    let name: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case email, role, name
        case createdAt = "created_at"
    }

    var userRole: UserRole {
        UserRole(rawValue: role) ?? .user
    }
}

struct MessageResponse: Codable {
    let message: String
}
