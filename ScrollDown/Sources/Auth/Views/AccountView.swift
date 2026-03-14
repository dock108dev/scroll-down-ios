//
//  AccountView.swift
//  ScrollDown
//
//  User account management: profile info, password change, logout, delete.
//

import SwiftUI

struct AccountView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showChangePassword = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            // Profile section
            Section("Account") {
                if let profile = authViewModel.profile {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(profile.email)
                            .foregroundStyle(.secondary)
                    }
                    if let name = profile.name {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(name)
                                .foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Text("Role")
                        Spacer()
                        Text(authViewModel.role.displayName)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(roleBadgeColor.opacity(0.15))
                            .foregroundStyle(roleBadgeColor)
                            .clipShape(Capsule())
                    }
                }
            }

            // Actions
            Section {
                Button("Change Password") {
                    showChangePassword = true
                }

                Button("Sign Out") {
                    Task { await authViewModel.logout() }
                }
                .foregroundStyle(.red)
            }

            // Danger zone
            Section {
                Button("Delete Account") {
                    showDeleteConfirmation = true
                }
                .foregroundStyle(.red)
            } footer: {
                Text("This permanently deletes your account and all associated data.")
                    .font(.caption)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView(authViewModel: authViewModel)
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task { await authViewModel.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All your data will be permanently removed.")
        }
    }

    private var roleBadgeColor: Color {
        switch authViewModel.role {
        case .admin: return .orange
        case .user: return GameTheme.accentColor
        case .guest: return .secondary
        }
    }
}

// MARK: - Change Password

struct ChangePasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    private var canSubmit: Bool {
        !currentPassword.isEmpty && !newPassword.isEmpty && newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                SecureField("Current Password", text: $currentPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("New Password", text: $newPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("Confirm New Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if let error = authViewModel.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                Button("Update Password") {
                    Task {
                        if await authViewModel.changePassword(current: currentPassword, new: newPassword) {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit || authViewModel.isLoading)

                Spacer()
            }
            .padding()
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
