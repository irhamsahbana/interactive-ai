//
//  VoiceManager.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import Foundation
import AVFoundation
import Combine
import Observation

@Observable class VoiceManager {
    var availableVoices: [VoiceChoice] = []
    var isLoading = false
    var errorMessage = ""
    
    // Singleton instance
    static let shared = VoiceManager()
    
    private init() {
        loadAvailableVoices()
    }
    
    func loadAvailableVoices() {
        isLoading = true
        errorMessage = ""
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let voices = AVSpeechSynthesisVoice.speechVoices()
                .map { VoiceChoice(voice: $0) }
                .sorted { $0.name < $1.name }
            
            DispatchQueue.main.async {
                self?.availableVoices = voices
                self?.isLoading = false
            }
        }
    }
    
    func voices(for language: Language) -> [VoiceChoice] {
        let prefix = language == .english ? "en" : "ko"
        return availableVoices.filter { $0.language.hasPrefix(prefix) }
    }
    
    func defaultVoice(for language: Language) -> VoiceChoice? {
        let voices = voices(for: language)
        return VoiceChoice.defaultVoice(for: language) ?? voices.first
    }
    
    func refreshVoices() {
        loadAvailableVoices()
    }
    
    // MARK: - Debug Information
    
    func printAvailableVoices() {
        print("=== Available Voices ===")
        for voice in availableVoices {
            print("ID: \(voice.id)")
            print("Name: \(voice.name)")
            print("Language: \(voice.language)")
            print("Accent: \(voice.accent)")
            print("---")
        }
    }
    
    func printVoicesForLanguage(_ language: Language) {
        let voices = voices(for: language)
        print("=== \(language.displayName) Voices ===")
        for voice in voices {
            print("\(voice.displayName) - \(voice.language) - \(voice.downloadStatus) - \(voice.qualityDescription)")
        }
    }
    
    // MARK: - Voice Download Helpers
    
    func downloadVoice(_ voice: VoiceChoice) {
        // Note: Voice downloading is handled by the system automatically
        // when the voice is first used. This method is for future reference.
        print("Voice \(voice.name) will be downloaded automatically when first used.")
    }
    
    func getDownloadedVoices(for language: Language) -> [VoiceChoice] {
        return voices(for: language).filter { $0.isDownloaded }
    }
    
    func getNotDownloadedVoices(for language: Language) -> [VoiceChoice] {
        return voices(for: language).filter { !$0.isDownloaded }
    }
}
