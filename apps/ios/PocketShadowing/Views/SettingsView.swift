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
                    Picker(L10n.myNativeLanguage, selection: $nativeLanguage) {
                        ForEach(UserSettings.availableLanguages) { language in
                            Text(language.displayName)
                                .tag(language.code)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        HStack {
                            Label(L10n.subscription, systemImage: "crown.fill")
                            Spacer()
                            if authManager.isMember {
                                Text(L10n.active)
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
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
                            Text(L10n.signOut)
                            Spacer()
                        }
                    }
                }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.done) {
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
