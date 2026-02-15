//
//  ProfileRepository.swift
//  PocketShadowing
//

import Foundation
import Supabase

/// Profile data from Supabase
struct ProfileDTO: Codable {
    let id: UUID
    let native_language: String
    let onboarding_completed: Bool
    let created_at: String?
    let updated_at: String?

    enum CodingKeys: String, CodingKey {
        case id, created_at, updated_at
        case native_language
        case onboarding_completed
    }
}

/// DTO for upserting profile (without read-only fields)
struct ProfileUpsertDTO: Codable {
    let id: UUID
    let native_language: String
    let onboarding_completed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case native_language
        case onboarding_completed
    }
}

/// Repository for user profile data in Supabase
class ProfileRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientManager.shared.client) {
        self.client = client
    }

    /// Fetch the current user's profile
    func fetchProfile() async throws -> ProfileDTO? {
        guard let userId = client.auth.currentUser?.id else { return nil }

        let response: [ProfileDTO] = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Create or update the current user's profile
    func upsertProfile(nativeLanguage: String, onboardingCompleted: Bool) async throws {
        guard let userId = client.auth.currentUser?.id else { return }

        let dto = ProfileUpsertDTO(
            id: userId,
            native_language: nativeLanguage,
            onboarding_completed: onboardingCompleted
        )

        try await client.database
            .from("profiles")
            .upsert(dto)
            .execute()
    }
}
