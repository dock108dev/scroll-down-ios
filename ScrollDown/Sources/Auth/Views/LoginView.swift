//
//  LoginView.swift
//  ScrollDown
//
//  Login screen with email/password fields and signup toggle.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var showForgotPassword = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo
            VStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                Text("Scroll Down Sports")
                    .font(.title2.weight(.bold))
                Text("Sign in to unlock all features")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Fields
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)

            // Error
            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Login button
            Button {
                Task { await authViewModel.login(email: email, password: password) }
            } label: {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text("Sign In")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(GameTheme.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
            .padding(.horizontal)

            // Links
            VStack(spacing: 12) {
                Button("Forgot Password?") {
                    showForgotPassword = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign Up") {
                        showSignup = true
                    }
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
            }

            // Continue as guest
            Button("Continue as Guest") {
                // Already guest — just dismiss
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 8)

            Spacer()
        }
        .sheet(isPresented: $showSignup) {
            SignupView(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(authViewModel: authViewModel)
        }
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if sent {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(GameTheme.accentColor)
                        Text("Check your email")
                            .font(.headline)
                        Text("If an account exists for \(email), we sent a reset link.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)

                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Send Reset Link") {
                        Task {
                            if await authViewModel.forgotPassword(email: email) {
                                sent = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || authViewModel.isLoading)
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
