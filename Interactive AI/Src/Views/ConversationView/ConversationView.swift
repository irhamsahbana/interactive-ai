//
//  ContentView.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import SwiftUI

struct ConversationView: View {
    let language: Language
    let voiceChoice: VoiceChoice?
    private var viewModel: ConversationViewModel

    init(language: Language = .english, voiceChoice: VoiceChoice? = nil) {
        self.language = language
        self.voiceChoice = voiceChoice ?? VoiceManager.shared.defaultVoice(for: language)
        self.viewModel = ConversationViewModel(language: language, voiceChoice: self.voiceChoice)
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Interactive AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Language and Voice indicators
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Text(language.flag)
                            .font(.title2)
                        Text(language.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2")
                            .font(.title3)
                            .foregroundColor(.blue)
                        Text(voiceChoice?.displayName ?? "No Voice Selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Conversation History at the top
            ConversationHistoryView(viewModel: viewModel)

            // Error message display
            if viewModel.hasError {
                ErrorMessageView(message: viewModel.speechState.errorMessage)
            }

            Spacer()

            // Bottom section - Controls and transcription for thumb accessibility
            VStack(spacing: 16) {
                // Transcribed text display - near microphone button
                TranscriptionView(viewModel: viewModel)

                // Spectrum visualization - show when recording
                // if viewModel.speechState.isRecording {
                //     SpectrumVisualizationView(
                //         spectrumData: viewModel.speechState.spectrumData,
                //         isRecording: viewModel.speechState.isRecording
                //     )
                //     .padding(.horizontal)
                // }

                // Recording status - near microphone button
                RecordingStatusView(viewModel: viewModel)

                // Microphone button - easily reachable with thumb
                MicrophoneButtonView(viewModel: viewModel)

                // TTS Test button
                TTSButtonView(viewModel: viewModel)
                
                // Action buttons - at the very bottom
                ActionButtonsView(viewModel: viewModel)
            }
        }
        .padding()
    }
}

// MARK: - Subviews
struct TranscriptionView: View {
    var viewModel: ConversationViewModel

    var body: some View {
        ScrollView {
            Text(viewModel.hasTranscribedText ? viewModel.speechState.transcribedText : viewModel.transcriptionPlaceholder)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(viewModel.hasTranscribedText ? .primary : .secondary)
        }
        .frame(maxHeight: 120)
    }
}



struct RecordingStatusView: View {
    var viewModel: ConversationViewModel

    var body: some View {
        HStack {
            Circle()
                .fill(viewModel.statusColor)
                .frame(width: 10, height: 10)
            Text(viewModel.statusText)
                .font(.caption)
        }
    }
}

struct MicrophoneButtonView: View {
    var viewModel: ConversationViewModel

    var body: some View {
        Button(action: {
            viewModel.toggleRecording()
        }) {
            Image(systemName: viewModel.microphoneSystemImage)
                .font(.system(size: 40))
                .foregroundColor(viewModel.microphoneButtonColor)
                .frame(width: 80, height: 80)
                .background(Circle().fill(Color.gray.opacity(0.2)))
        }
        .disabled(!viewModel.speechState.isAuthorized)
    }
}

struct TTSButtonView: View {
    var viewModel: ConversationViewModel

    var body: some View {
        Button(action: {
            viewModel.testTTS()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2")
                    .font(.title3)
                Text("Test Voice")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(20)
        }
    }
}

struct ActionButtonsView: View {
    var viewModel: ConversationViewModel

    var body: some View {
        HStack(spacing: 20) {
            Button("Clear Text") {
                viewModel.clearTranscription()
            }
            .foregroundColor(.secondary)

            if !viewModel.conversations.isEmpty {
                Button("Clear All") {
                    viewModel.clearConversation()
                }
                .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    ConversationView(language: .english, voiceChoice: nil)
}
