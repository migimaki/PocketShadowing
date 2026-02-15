//
//  WelcomeView.swift
//  PocketShadowing
//

import SwiftUI

struct WelcomeView: View {
    @State private var showEmailAuth = false
    @AppStorage("nativeLanguage") private var nativeLanguage: String = UserSettings.shared.nativeLanguage

    var body: some View {
        ZStack {
            GradientBackground()

            VStack {
                Spacer()

                Text("PocketShadowing")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                // Native language picker
                VStack(spacing: 8) {
                    Text("Your Language")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    Picker("Language", selection: $nativeLanguage) {
                        ForEach(UserSettings.availableLanguages) { language in
                            Text(language.displayName)
                                .tag(language.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.appPrimary)
                }
                .padding(.bottom, 24)

                Button {
                    showEmailAuth = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                        Text("Sign in with Email")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
        }
    }
}

#Preview {
    WelcomeView()
}
