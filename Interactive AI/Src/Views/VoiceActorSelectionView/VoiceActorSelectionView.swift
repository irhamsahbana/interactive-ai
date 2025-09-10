//
//  VoiceActorSelectionView.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import SwiftUI
import AVFoundation

struct VoiceActorSelectionView: View {
    let language: Language
    @State private var selectedVoice: VoiceChoice?
    @State private var navigateToConversation = false
    @State private var isPlayingPreview = false
    @State private var playingVoice: VoiceChoice?
    @State private var voiceManager = VoiceManager.shared
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    init(language: Language) {
        self.language = language
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Text(language.flag)
                            .font(.title)
                        Text("Voice Selection")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }

                    Text("Choose your preferred voice for text-to-speech")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Voice List
                if voiceManager.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading available voices...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(voiceManager.voices(for: language)) { voice in
                                VoiceOptionView(
                                    voice: voice,
                                    isSelected: selectedVoice?.id == voice.id,
                                    isPlaying: playingVoice?.id == voice.id,
                                    onSelect: { selectedVoice = voice },
                                    onPreview: { playVoicePreview(voice) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Spacer()

                // Continue Button
                Button(action: {
                    if selectedVoice == nil {
                        selectedVoice = voiceManager.defaultVoice(for: language)
                    }
                    navigateToConversation = true
                }) {
                    Text("Continue")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedVoice != nil ? Color.blue : Color.gray)
                        .cornerRadius(16)
                }
                .disabled(selectedVoice == nil)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: ConversationView(language: language, voiceChoice: selectedVoice),
                    isActive: $navigateToConversation
                ) {
                    EmptyView()
                }
            )
        }
    }

    private func playVoicePreview(_ voice: VoiceChoice) {
        // Stop any currently playing voice
        if isPlayingPreview {
            stopVoicePreview()
        }

        playingVoice = voice
        isPlayingPreview = true

        let utterance = AVSpeechUtterance(string: voice.previewText)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voice.id)
        utterance.rate = 0.5
        utterance.volume = 0.8

        // Use the persistent synthesizer instance
        speechSynthesizer.speak(utterance)

        // Reset playing state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            playingVoice = nil
            isPlayingPreview = false
        }
    }

    private func stopVoicePreview() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        playingVoice = nil
        isPlayingPreview = false
    }
}

struct VoiceOptionView: View {
    let voice: VoiceChoice
    let isSelected: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Voice info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(voice.flag)
                            .font(.title2)
                        Text(voice.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: 8) {
                        Text(voice.accent)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)

                        Text(voice.language)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                // Preview button
                Button(action: onPreview) {
                    Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(isPlaying ? .red : .blue)
                }
                .buttonStyle(PlainButtonStyle())

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VoiceActorSelectionView(language: .english)
}
