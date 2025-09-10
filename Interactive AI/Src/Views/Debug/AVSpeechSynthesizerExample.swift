//
//  AVSpeechSynthesizerExample.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import SwiftUI
import AVFoundation

// MARK: - Correct Pattern for iOS 15/16+

struct CorrectSpeechExample: View {
    // ✅ CORRECT: Declare synthesizer as a persistent property
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack {
            Button("Speak") {
                speakText("Hello, this is a test!")
            }
        }
    }

    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 0.8

        // ✅ CORRECT: Use the persistent synthesizer instance
        speechSynthesizer.speak(utterance)
    }
}

// MARK: - Incorrect Pattern (Don't do this on iOS 15/16+)

struct IncorrectSpeechExample: View {
    var body: some View {
        VStack {
            Button("Speak") {
                speakText("This won't work properly on iOS 15/16+")
            }
        }
    }

    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 0.8

        // ❌ INCORRECT: Creating new synthesizer each time
        let synthesizer = AVSpeechSynthesizer() // This causes issues on iOS 15/16+
        synthesizer.speak(utterance)
    }
}

// MARK: - Class-based Example

class SpeechService: ObservableObject {
    // ✅ CORRECT: Declare synthesizer as a persistent property
    private let speechSynthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 0.8

        // ✅ CORRECT: Use the persistent synthesizer instance
        speechSynthesizer.speak(utterance)
    }

    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}

#Preview {
    CorrectSpeechExample()
//    IncorrectSpeechExample()
}
