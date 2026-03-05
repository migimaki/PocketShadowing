//
//  WelcomeView.swift
//  PocketShadowing
//

import SwiftUI

struct WelcomeView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showEmailAuth = false
    @State private var showEmailAuthForSignUp = false
    @AppStorage("nativeLanguage") private var nativeLanguage: String = UserSettings.shared.nativeLanguage

    var body: some View {
        ZStack {
            GradientBackground()

            VStack {
                HStack {
                    Spacer()
                    Picker("Language", selection: $nativeLanguage) {
                        ForEach(UserSettings.availableLanguages) { language in
                            Text(language.displayName)
                                .tag(language.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.appPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                Text("PocketShadowing")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                VStack(spacing: 12) {
                    // Continue with Google
                    Button {
                        Task { await authManager.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            Text("G")
                                .font(.system(size: 20, weight: .bold))
                            Text("Continue with Google")
                        }
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Continue with Apple
                    Button {
                        // TODO: Implement Apple Sign-In
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo")
                            Text("Continue with Apple")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Sign in with Email
                    Button {
                        showEmailAuth = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                            Text("Sign in with Email")
                        }
                        .font(.headline)
                        .foregroundStyle(Color.appForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)

                // Sign Up link
                Button {
                    showEmailAuthForSignUp = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Sign Up")
                            .foregroundStyle(Color.appPrimary)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
        }
        .sheet(isPresented: $showEmailAuthForSignUp) {
            EmailAuthView(initialSignUp: true)
        }
    }
}

#Preview {
    WelcomeView()
}
