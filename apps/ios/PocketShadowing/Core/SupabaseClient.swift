//
//  SupabaseClient.swift
//  PocketShadowing
//
//  Created by Claude Code on 2025/11/01.
//

import Foundation
import Supabase

/// Singleton Supabase client for the app
class SupabaseClientManager {
    static let shared = SupabaseClientManager()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL: \(SupabaseConfig.supabaseURL)")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
}
