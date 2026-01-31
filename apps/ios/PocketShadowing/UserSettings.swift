//
//  UserSettings.swift
//  WalkingTalking
//
//  Created by Claude on 2025/11/14.
//

import SwiftUI

/// User preferences and settings for the app
@Observable
class UserSettings {
    /// Shared instance for app-wide access
    static let shared = UserSettings()

    /// User's native language (for future UI localization)
    /// Currently only affects the learning language options
    @ObservationIgnored
    @AppStorage("nativeLanguage") var nativeLanguage: String = "en"

    /// Learning language is hard-coded to English
    /// This constant ensures consistency across the app
    static let learningLanguage: String = "en"

    /// Available languages for native language selection
    /// Used for showing translations in lessons
    static let availableLanguages = [
        Language(code: "en", name: "English", nativeName: "English"),
        Language(code: "ja", name: "Japanese", nativeName: "日本語"),
        Language(code: "fr", name: "French", nativeName: "Français")
    ]

    /// Get language object from code
    func language(for code: String) -> Language? {
        Self.availableLanguages.first { $0.code == code }
    }

    /// Get native language object
    var nativeLanguageObject: Language {
        language(for: nativeLanguage) ?? Self.availableLanguages[0]
    }

    private init() {}
}

/// Language model
struct Language: Identifiable, Hashable {
    let code: String
    let name: String
    let nativeName: String

    var id: String { code }

    /// Display name showing both English and native name
    var displayName: String {
        if name == nativeName {
            return name
        }
        return "\(name) (\(nativeName))"
    }
}
