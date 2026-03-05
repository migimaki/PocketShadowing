//
//  SettingsView.swift
//  WalkingTalking
//
//  Settings view for language preferences
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @AppStorage("nativeLanguage") private var nativeLanguage: String = "en"

    var body: some View {
        NavigationStack {
            ZStack {
                // Background layer
                GradientBackground()

                // Content layer
                Form {
                Section {
                    Text("This app helps you practice English through shadowing. Select your native language for future interface localization.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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

                    LabeledContent("Learning Language") {
                        Text("English")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            await authManager.signOut()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
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
        .environment(AuthManager())
}
