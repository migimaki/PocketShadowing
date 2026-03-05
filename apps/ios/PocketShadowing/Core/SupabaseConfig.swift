//
//  SupabaseConfig.swift
//  PocketShadowing
//
//  Configuration for Supabase connection
//  Actual values are stored in SupabaseConfig.generated.swift (gitignored)
//

import Foundation

struct SupabaseConfig {
    // Values are loaded from SupabaseConfig.generated.swift
    // That file is gitignored for security
    static let supabaseURL = SUPABASE_URL_VALUE
    static let supabaseAnonKey = SUPABASE_ANON_KEY_VALUE
}
