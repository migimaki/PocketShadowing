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
                    .listRowBackground(Color(red: 0x22/255, green: 0x0D/255, blue: 0x34/255))
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
                    .listRowBackground(Color(red: 0x22/255, green: 0x0D/255, blue: 0x34/255))
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
                    .listRowBackground(Color(red: 0x22/255, green: 0x0D/255, blue: 0x34/255))
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
