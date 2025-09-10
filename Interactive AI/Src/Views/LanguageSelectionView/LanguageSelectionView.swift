//
//  LanguageSelectionView.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import SwiftUI

struct LanguageSelectionView: View {
    @State private var selectedLanguage: Language = .english
    @State private var navigateToConversation = false

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Text("Interactive AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Choose your preferred language")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                Spacer()

                // Language Selection
                VStack(spacing: 24) {
                    LanguageOptionView(
                        language: .english,
                        isSelected: selectedLanguage == .english,
                        action: { selectedLanguage = .english }
                    )

                    LanguageOptionView(
                        language: .korean,
                        isSelected: selectedLanguage == .korean,
                        action: { selectedLanguage = .korean }
                    )
                }

                Spacer()

                // Continue Button
                Button(action: {
                    navigateToConversation = true
                }) {
                    Text("Continue")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: VoiceActorSelectionView(language: selectedLanguage),
                    isActive: $navigateToConversation
                ) {
                    EmptyView()
                }
            )
        }
    }
}

struct LanguageOptionView: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Flag icon
                Text(language.flag)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(language.nativeName)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 32)
    }
}

#Preview {
    LanguageSelectionView()
}
