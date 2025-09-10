//
//  LanguageManager.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import Foundation
import Combine
import Observation

@Observable class LanguageManager {
    var selectedLanguage: Language = .english
    
    // Singleton instance
    static let shared = LanguageManager()
    
    private init() {
        // Load saved language preference if available
        loadLanguagePreference()
    }
    
    func setLanguage(_ language: Language) {
        selectedLanguage = language
        saveLanguagePreference()
    }
    
    private func saveLanguagePreference() {
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "SelectedLanguage")
    }
    
    private func loadLanguagePreference() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "SelectedLanguage"),
           let language = Language(rawValue: savedLanguage) {
            selectedLanguage = language
        }
    }
}
