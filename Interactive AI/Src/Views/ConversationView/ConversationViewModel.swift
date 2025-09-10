//
//  ConversationViewModel.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import SwiftUI
import Combine
import Observation

@Observable class ConversationViewModel {
    // MARK: - Published Properties
    var speechState = SpeechRecognitionState()
    var conversations: [ConversationMessage] = []
    var isProcessingAI = false
    let language: Language
    let voiceChoice: VoiceChoice?

    // MARK: - Managers
    @ObservationIgnored private let speechManager: SpeechManager
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var errorDismissalTimer: Timer?

    // MARK: - Initialization
    init(language: Language = .english, voiceChoice: VoiceChoice? = nil, speechManager: SpeechManager? = nil) {
        self.language = language
        self.voiceChoice = voiceChoice ?? VoiceManager.shared.defaultVoice(for: language)
        self.speechManager = speechManager ?? SpeechManager(language: language, voiceChoice: self.voiceChoice)
        setupBindings()
    }

    deinit {
        cancelErrorDismissal()
    }

    // MARK: - Private Methods
    private func setupBindings() {
        // Bind SpeechManager properties to our state
        speechManager.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.speechState.isRecording = isRecording
            }
            .store(in: &cancellables)

        speechManager.$transcribedText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.speechState.transcribedText = text
            }
            .store(in: &cancellables)

        speechManager.$isAuthorized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthorized in
                self?.speechState.isAuthorized = isAuthorized
            }
            .store(in: &cancellables)

        speechManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.speechState.errorMessage = errorMessage

                // Auto-dismiss error message after 3 seconds
                if !errorMessage.isEmpty {
                    self?.scheduleErrorDismissal()
                } else {
                    self?.cancelErrorDismissal()
                }
            }
            .store(in: &cancellables)

        speechManager.$spectrumData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] spectrumData in
                self?.speechState.spectrumData = spectrumData
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods
    func startRecording() {
        speechManager.startRecording()
    }

    func stopRecording() {
        speechManager.stopRecording()

        // Add user message to conversation if we have transcribed text
        if !speechState.transcribedText.isEmpty {
            let userMessage = ConversationMessage(
                content: speechState.transcribedText,
                isFromUser: true
            )
            conversations.append(userMessage)

            // TODO: Process with AI in Phase 2
            // processWithAI(userMessage.content)
        }
    }

    func toggleRecording() {
        if speechState.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func clearTranscription() {
        // Use SpeechManager's clearTranscription method for proper cleanup
        speechManager.clearTranscription()
    }

    func clearConversation() {
        conversations.removeAll()
        clearTranscription()
    }
    
    func testTTS() {
        let testText = voiceChoice?.previewText ?? "Hello! I'm your AI assistant. How can I help you today?"
        speechManager.speakText(testText)
    }

    // MARK: - Error Message Auto-Dismissal
    private func scheduleErrorDismissal() {
        // Cancel any existing timer
        cancelErrorDismissal()

        // Schedule new timer to dismiss error after 3 seconds
        errorDismissalTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.clearErrorMessage()
        }
    }

    private func cancelErrorDismissal() {
        errorDismissalTimer?.invalidate()
        errorDismissalTimer = nil
    }

    private func clearErrorMessage() {
        speechManager.errorMessage = ""
        cancelErrorDismissal()
    }

    // MARK: - Future AI Integration Methods
    private func processWithAI(_ userInput: String) {
        // This will be implemented in Phase 2 - AI Integration
        isProcessingAI = true

        // Simulate AI processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let aiResponse = ConversationMessage(
                content: "AI response will be implemented in Phase 2",
                isFromUser: false
            )
            self?.conversations.append(aiResponse)
            self?.isProcessingAI = false
        }
    }

    // MARK: - Computed Properties
    var microphoneButtonColor: Color {
        speechState.isRecording ? .red : .blue
    }

    var microphoneSystemImage: String {
        speechState.isRecording ? "mic.fill" : "mic"
    }

    var statusText: String {
        speechState.isRecording ? "Recording..." : "Ready"
    }

    var statusColor: Color {
        speechState.isRecording ? .red : .gray
    }

    var transcriptionPlaceholder: String {
        "Tap the microphone to start speaking..."
    }

    var hasTranscribedText: Bool {
        !speechState.transcribedText.isEmpty
    }

    var hasError: Bool {
        !speechState.errorMessage.isEmpty
    }
}
