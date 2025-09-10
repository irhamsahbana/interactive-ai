//
//  Models.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import Foundation
import AVFoundation

// MARK: - Speech Recognition Models
struct SpeechRecognitionState {
    var isRecording: Bool = false
    var transcribedText: String = ""
    var isAuthorized: Bool = false
    var errorMessage: String = ""
    var spectrumData: SpectrumData? = nil
}

struct ConversationMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let audioURL: URL?

    init(content: String, isFromUser: Bool, audioURL: URL? = nil) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.audioURL = audioURL
    }
}

struct AIResponse {
    let text: String
    let audioData: Data?
    let confidence: Float

    init(text: String, audioData: Data? = nil, confidence: Float = 1.0) {
        self.text = text
        self.audioData = audioData
        self.confidence = confidence
    }
}

struct SpeechAnalysis {
    let transcription: String
    let confidence: Float
    let pronunciationScore: Float?

    init(transcription: String, confidence: Float, pronunciationScore: Float? = nil) {
        self.transcription = transcription
        self.confidence = confidence
        self.pronunciationScore = pronunciationScore
    }
}
