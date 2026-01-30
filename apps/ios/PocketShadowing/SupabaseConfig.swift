//
//  SupabaseConfig.swift
//  PocketShadowing
//
//  Configuration loaded from Info.plist (injected via Config.xcconfig at build time)
//  See Config.example.xcconfig for setup instructions
//

import Foundation

struct SupabaseConfig {
    static let supabaseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !url.isEmpty,
              !url.contains("$") else { // Check for unexpanded variable
            fatalError("SUPABASE_URL not configured. Did you create Config.xcconfig and link it in Xcode?")
        }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty,
              !key.contains("your_") else { // Check for placeholder
            fatalError("SUPABASE_ANON_KEY not configured. Did you create Config.xcconfig and link it in Xcode?")
        }
        return key
    }()
}
