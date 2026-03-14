//
//  AuthViewModel.swift
//  ScrollDown
//
//  Central authentication state manager.
//  Persists login via Keychain, validates token on app launch.
//

import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()

    @Published var isAuthenticated = false
    @Published var role: UserRole = .guest
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService

    private init(authService: AuthService = .shared) {
        self.authService = authService
    }

    // MARK: - Computed

    var isAdmin: Bool { role.isAdmin }
    var isGuest: Bool { role == .guest }
    var displayName: String { profile?.name ?? profile?.email ?? "Guest" }

    // MARK: - Lifecycle

    /// Call on app launch to validate existing token
    func validateSession() async {
        guard await authService.hasToken else {
            isAuthenticated = false
            role = .guest
            return
        }

        do {
            let user = try await authService.fetchProfile()
            profile = user
            role = user.userRole
            isAuthenticated = true
        } catch {
            // Token expired or invalid — clear
            await authService.logout()
            isAuthenticated = false
            role = .guest
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.login(email: email, password: password)
            role = response.userRole
            isAuthenticated = true
            // Fetch full profile
            if let user = try? await authService.fetchProfile() {
                profile = user
            }
            HapticService.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
            HapticService.notification(.error)
        }
        isLoading = false
    }

    // MARK: - Signup

    func signup(email: String, password: String, name: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.signup(email: email, password: password, name: name)
            role = response.userRole
            isAuthenticated = true
            if let user = try? await authService.fetchProfile() {
                profile = user
            }
            HapticService.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
            HapticService.notification(.error)
        }
        isLoading = false
    }

    // MARK: - Logout

    func logout() async {
        await authService.logout()
        isAuthenticated = false
        role = .guest
        profile = nil
        HapticService.impact(.light)
    }

    // MARK: - Password

    func changePassword(current: String, new: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await authService.changePassword(current: current, new: new)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func forgotPassword(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await authService.forgotPassword(email: email)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Delete Account

    func deleteAccount() async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await authService.deleteAccount()
            await authService.logout()
            isAuthenticated = false
            role = .guest
            profile = nil
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
