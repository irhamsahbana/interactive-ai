//
//  SpeechManager.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import AVFoundation
import Speech
import SwiftUI

class SpeechManager: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false
    @Published var errorMessage = ""

    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioSession = AVAudioSession.sharedInstance()

    init() {
        requestPermissions()
    }

    deinit {
        // Ensure cleanup when object is deallocated
        stopRecording()
    }

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isAuthorized = true
                case .denied, .restricted, .notDetermined:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition not authorized"
                @unknown default:
                    self?.isAuthorized = false
                    self?.errorMessage = "Unknown authorization status"
                }
            }
        }

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted {
                        self?.errorMessage = "Microphone access not granted"
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted {
                        self?.errorMessage = "Microphone access not granted"
                    }
                }
            }
        }
    }

    func startRecording() {
        guard isAuthorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }

        // Ensure we're in a clean state
        if isRecording || audioEngine.isRunning {
            stopRecording()
            // Give a brief moment for cleanup to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startRecordingInternal()
            }
        } else {
            startRecordingInternal()
        }
    }

    private func startRecordingInternal() {
        // Clear any previous transcription for fresh start
        transcribedText = ""
        errorMessage = ""

        do {
            try startSpeechRecognition()
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    func clearTranscription() {
        // Stop recording if active
        if isRecording {
            stopRecording()
        }

        // Clear transcribed text and errors
        transcribedText = ""
        errorMessage = ""
    }

    func stopRecording() {
        // Stop audio engine first
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Remove any existing taps from input node
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        // Clean up recognition components
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        // Reset recording state
        isRecording = false

        // Reset audio session
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    private func startSpeechRecognition() throws {
        // Cancel previous task and clean up
        recognitionTask?.cancel()
        recognitionTask = nil

        // Clear any previous transcription for fresh start
        transcribedText = ""

        // Ensure audio engine is stopped and clean
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Remove any existing taps
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        // Configure audio session
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }

        recognitionRequest.shouldReportPartialResults = true

        // Configure audio engine with fresh setup
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install tap on clean input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // Prepare and start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString

                    if result.isFinal {
                        self?.stopRecording()
                    }
                }

                if let error = error {
                    let msg = error.localizedDescription
                    // Treat “No speech detected” as a non-fatal info
                    if msg.localizedCaseInsensitiveContains("No speech detected") {
                        self?.errorMessage = ""   // don’t surface it to UI
                    } else if msg.localizedCaseInsensitiveContains("Recognition request was canceled") {
                        self?.errorMessage = ""   // don’t surface it to UI
                    } else {
                        self?.errorMessage = msg
                    }
                    self?.stopRecording()
                }
            }
        }
    }
}
