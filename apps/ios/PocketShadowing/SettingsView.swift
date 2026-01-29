//
//  SettingsView.swift
//  WalkingTalking
//
//  Settings view for language preferences
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("learningLanguage") private var learningLanguage: String = "en"
    @AppStorage("nativeLanguage") private var nativeLanguage: String = "en"

    private var settings: UserSettings { UserSettings.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background layer
                GradientBackground()

                // Content layer
                Form {
                Section {
                    Text("Select your native language and the language you want to learn. The app will show lessons in your chosen learning language.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section("Learning Language") {
                    Picker("I want to learn", selection: $learningLanguage) {
                        ForEach(UserSettings.availableLanguages) { language in
                            Text(language.displayName)
                                .tag(language.code)
                        }
                    }

                    if learningLanguage != "en" {
                        Label {
                            Text("Lessons will be in \(settings.language(for: learningLanguage)?.displayName ?? "")")
                                .font(.caption)
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }

                Section("Native Language (Future Feature)") {
                    Picker("My native language", selection: $nativeLanguage) {
                        ForEach(UserSettings.availableLanguages) { language in
                            Text(language.displayName)
                                .tag(language.code)
                        }
                    }

                    Text("Currently the app interface is in English. In the future, the interface will be localized to your native language.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("About") {
                    LabeledContent("Version") {
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    LabeledContent("Supported Languages") {
                        Text("\(UserSettings.availableLanguages.count)")
                            .foregroundColor(.secondary)
                    }
                }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
