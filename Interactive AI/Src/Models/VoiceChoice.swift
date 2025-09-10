//
//  VoiceChoice.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import Foundation
import AVFoundation

struct VoiceChoice: Identifiable, Hashable {
    let id: String
    let name: String
    let language: String
    let accent: String
    let isDownloaded: Bool
    let quality: AVSpeechSynthesisVoiceQuality

    init(voice: AVSpeechSynthesisVoice) {
        self.id = voice.identifier
        self.name = voice.name
        self.language = voice.language
        self.quality = voice.quality
        self.isDownloaded = voice.quality == .enhanced || voice.quality == .default

        // Extract accent from voice name and language
        self.accent = VoiceChoice.extractAccent(from: voice.language)
    }

    var displayName: String {
        return "\(name) (\(accent))"
    }

    var flag: String {
        return VoiceChoice.flagForLanguage(language)
    }

    var previewText: String {
        if language.hasPrefix("en") {
            return "Hello! I'm your AI assistant. How can I help you today?"
        } else if language.hasPrefix("ko") {
            return "안녕하세요! 저는 당신의 AI 어시스턴트입니다. 오늘 어떻게 도와드릴까요?"
        } else {
            return "Hello! I'm your AI assistant. How can I help you today?"
        }
    }

    var qualityDescription: String {
        switch quality {
        case .default:
            return "Default"
        case .enhanced:
            return "Enhanced"
        case .premium:
            return "Premium"
        @unknown default:
            return "Unknown"
        }
    }

    var downloadStatus: String {
        if isDownloaded {
            return "Downloaded"
        } else {
            return "Not Downloaded"
        }
    }

    var downloadStatusColor: String {
        if isDownloaded {
            return "green"
        } else {
            return "orange"
        }
    }

    // MARK: - Static Methods

    static func voices(for languagePrefix: String) -> [VoiceChoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(languagePrefix) }
            .map { VoiceChoice(voice: $0) }
            .sorted { $0.name < $1.name }
    }

    static func voices(for language: Language) -> [VoiceChoice] {
        let prefix = language == .english ? "en" : "ko"
        return voices(for: prefix)
    }

    static func defaultVoice(for language: Language) -> VoiceChoice? {
        let voices = voices(for: language)
        // Try to find a common default voice, fallback to first available
        let defaultNames = language == .english ? ["Samantha", "Alex"] : ["Yuna", "Kyoko"]

        for defaultName in defaultNames {
            if let voice = voices.first(where: { $0.name.contains(defaultName) }) {
                return voice
            }
        }

        return voices.first
    }

    // MARK: - Helper Methods
    private static func extractAccent(from language: String) -> String {
        if language.contains("en-US") {
            return "US"
        } else if language.contains("en-GB") {
            return "UK"
        } else if language.contains("en-AU") {
            return "AU"
        } else if language.contains("en-IE") {
            return "IE"
        } else if language.contains("en-ZA") {
            return "ZA"
        } else if language.contains("en-IN") {
            return "IN"
        } else if language.contains("ko-KR") {
            return "KR"
        } else if language.contains("ja-JP") {
            return "JP"
        } else if language.contains("en") {
            return "EN"
        } else if language.contains("ko") {
            return "KO"
        } else {
            return language.uppercased()
        }
    }

    private static func flagForLanguage(_ language: String) -> String {
        if language.contains("en-US") {
            return "🇺🇸"
        } else if language.contains("en-GB") {
            return "🇬🇧"
        } else if language.contains("en-AU") {
            return "🇦🇺"
        } else if language.contains("en-IE") {
            return "🇮🇪"
        } else if language.contains("en-ZA") {
            return "🇿🇦"
        } else if language.contains("en-IN") {
            return "🇮🇳"
        } else if language.contains("ko-KR") {
            return "🇰🇷"
        } else if language.contains("ja-JP") {
            return "🇯🇵"
        } else if language.hasPrefix("en") {
            return "🇺🇸"
        } else if language.hasPrefix("ko") {
            return "🇰🇷"
        } else {
            return "🌍"
        }
    }
}
