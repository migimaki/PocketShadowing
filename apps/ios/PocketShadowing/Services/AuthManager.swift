//
//  AuthManager.swift
//  PocketShadowing
//

import Foundation
import Supabase

@Observable
@MainActor
class AuthManager {
    var isAuthenticated = false
    var hasCompletedOnboarding = false
    var isLoading = true
    var errorMessage: String?

    private let client = SupabaseClientManager.shared.client
    private let profileRepository = ProfileRepository()

    init() {
        Task {
            await restoreSession()
            await listenToAuthChanges()
        }
    }

    var currentUserEmail: String? {
        client.auth.currentUser?.email
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            try await client.auth.signIn(email: email, password: password)
            isAuthenticated = true
            await checkProfile()
        } catch {
            print("Sign in error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        errorMessage = nil
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            if response.session != nil {
                isAuthenticated = true
                // New user — onboarding not completed yet
                hasCompletedOnboarding = false
            } else {
                errorMessage = "Check your email to confirm your account, then sign in."
            }
        } catch {
            print("Sign up error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            hasCompletedOnboarding = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    private func checkProfile() async {
        do {
            if let profile = try await profileRepository.fetchProfile() {
                hasCompletedOnboarding = profile.onboarding_completed
                if profile.onboarding_completed {
                    UserSettings.shared.nativeLanguage = profile.native_language
                }
            } else {
                hasCompletedOnboarding = false
            }
        } catch {
            print("Failed to fetch profile: \(error)")
            hasCompletedOnboarding = false
        }
    }

    private func restoreSession() async {
        do {
            _ = try await client.auth.session
            isAuthenticated = true
            await checkProfile()
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    private func listenToAuthChanges() async {
        for await (event, _) in client.auth.authStateChanges {
            switch event {
            case .signedIn:
                isAuthenticated = true
                await checkProfile()
            case .signedOut:
                isAuthenticated = false
                hasCompletedOnboarding = false
            default:
                break
            }
        }
    }
}
