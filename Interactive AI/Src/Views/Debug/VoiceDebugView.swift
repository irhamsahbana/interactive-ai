//
//  VoiceDebugView.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import SwiftUI
import AVFoundation

struct VoiceDebugView: View {
    @State private var voiceManager = VoiceManager.shared
    @State private var selectedLanguage: Language = .english
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var playingVoice: VoiceChoice?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Language Picker
                Picker("Language", selection: $selectedLanguage) {
                    Text("English").tag(Language.english)
                    Text("Korean").tag(Language.korean)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Available Voices
                List(voiceManager.voices(for: selectedLanguage), id: \.id) { voice in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(voice.flag)
                                .font(.title2)
                            Text(voice.name)
                                .font(.headline)
                            Spacer()

                            // Play/Stop Button
                            Button(action: {
                                if playingVoice?.id == voice.id {
                                    stopVoicePreview()
                                } else {
                                    playVoicePreview(voice)
                                }
                            }) {
                                Image(systemName: playingVoice?.id == voice.id ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(playingVoice?.id == voice.id ? .red : .blue)
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Download Status Indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(voice.isDownloaded ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(voice.downloadStatus)
                                    .font(.caption)
                                    .foregroundColor(voice.isDownloaded ? .green : .orange)
                            }
                        }

                        HStack(spacing: 12) {
                            Text(voice.accent)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(6)

                            Text(voice.qualityDescription)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(6)
                        }

                        // Voice ID and Language
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ID: \(voice.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Language: \(voice.language)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Download Statistics
                let voices = voiceManager.voices(for: selectedLanguage)
                let downloadedCount = voices.filter { $0.isDownloaded }.count
                let totalCount = voices.count

                VStack(spacing: 8) {
                    Text("Download Status")
                        .font(.headline)

                    HStack(spacing: 20) {
                        VStack {
                            Text("\(downloadedCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Downloaded")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text("\(totalCount - downloadedCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Not Downloaded")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text("\(totalCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Refresh Button
                Button("Refresh Voices") {
                    voiceManager.refreshVoices()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationTitle("Voice Debug")
            .onAppear {
                voiceManager.printVoicesForLanguage(selectedLanguage)
            }
        }
    }

    private func playVoicePreview(_ voice: VoiceChoice) {
        // Stop any currently playing voice
        if playingVoice != nil {
            stopVoicePreview()
        }

        playingVoice = voice

        let utterance = AVSpeechUtterance(string: voice.previewText)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voice.id)
        utterance.rate = 0.5
        utterance.volume = 0.8

        // Use the persistent synthesizer instance
        speechSynthesizer.speak(utterance)

        // Reset playing state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            playingVoice = nil
        }
    }

    private func stopVoicePreview() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        playingVoice = nil
    }
}

#Preview {
    VoiceDebugView()
}
