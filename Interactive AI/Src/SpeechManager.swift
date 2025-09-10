//
//  SpeechManager.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import AVFoundation
import Speech
import SwiftUI

// MARK: - Speech Analysis Models
struct TranscriptionSegment {
    let text: String
    let timestamp: Date
    let duration: TimeInterval

    init(text: String, timestamp: Date = Date(), duration: TimeInterval = 0) {
        self.text = text
        self.timestamp = timestamp
        self.duration = duration
    }
}

struct SpeechMetrics {
    let wpm: Int
    let averagePauseLength: TimeInterval
    let pauseCount: Int
    let totalDuration: TimeInterval
    let wordCount: Int

    var formattedString: String {
        return "WPM: \(wpm), pause length: \(String(format: "%.1f", averagePauseLength))s, pause count: \(pauseCount)"
    }
}

class SpeechManager: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false
    @Published var errorMessage = ""
    @Published var spectrumData: SpectrumData?

    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioSession = AVAudioSession.sharedInstance()

    // MARK: - Audio Spectrum Analysis
    private let spectrumAnalyzer = AudioSpectrumAnalyzer()

    // MARK: - Speech Analysis Properties
    private var recordingStartTime: Date?
    private var lastTranscriptionTime: Date?
    private var transcriptionSegments: [TranscriptionSegment] = []
    private var pauseThreshold: TimeInterval = 0.5 // 500ms pause threshold

    init() {
        requestPermissions()
        setupSpectrumAnalyzer()
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

        // Initialize speech analysis tracking
        recordingStartTime = Date()
        lastTranscriptionTime = Date()
        transcriptionSegments.removeAll()

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

        // Clear analysis data
        recordingStartTime = nil
        lastTranscriptionTime = nil
        transcriptionSegments.removeAll()
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

        // Stop spectrum analysis
        spectrumAnalyzer.stopAnalysis()

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

        // Set preferred sample rate for better compatibility
        try audioSession.setPreferredSampleRate(44100.0)
        try audioSession.setPreferredInputNumberOfChannels(1)

        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true

        // Configure audio engine with fresh setup
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Create a valid recording format
        var recordingFormat: AVAudioFormat

        if let customFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: inputFormat.sampleRate,
            channels: min(inputFormat.channelCount, 1), // Use mono for speech recognition
            interleaved: false
        ) {
            recordingFormat = customFormat
        } else {
            // Fallback to input format if custom format creation fails
            recordingFormat = inputFormat
        }

        // Install tap on clean input node with validated format
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            // Process audio for spectrum analysis
            self?.spectrumAnalyzer.processAudioBuffer(buffer)
        }

        // Prepare and start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true

        // Start spectrum analysis
        spectrumAnalyzer.startAnalysis()

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.handleRecognitionResult(result)
                }

                if let error = error {
                    let msg = error.localizedDescription
                    // Treat "No speech detected" as a non-fatal info
                    if msg.localizedCaseInsensitiveContains("No speech detected") {
                        self?.errorMessage = ""   // don't surface it to UI
                    } else if msg.localizedCaseInsensitiveContains("Recognition request was canceled") {
                        self?.errorMessage = ""   // don't surface it to UI
                    } else {
                        self?.errorMessage = msg
                    }
                    self?.stopRecording()
                }
            }
        }
    }

    // MARK: - Speech Analysis Methods
    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult) {
        let currentTime = Date()
        let currentText = result.bestTranscription.formattedString

        // Track transcription segments for analysis
        if let lastTime = lastTranscriptionTime {
            let timeSinceLastTranscription = currentTime.timeIntervalSince(lastTime)

            // If there's a significant pause, record it
            if timeSinceLastTranscription > pauseThreshold {
                let pauseSegment = TranscriptionSegment(
                    text: "",
                    timestamp: lastTime,
                    duration: timeSinceLastTranscription
                )
                transcriptionSegments.append(pauseSegment)
            }
        }

        // Record the current transcription segment
        let textSegment = TranscriptionSegment(
            text: currentText,
            timestamp: currentTime,
            duration: 0
        )
        transcriptionSegments.append(textSegment)

        lastTranscriptionTime = currentTime

        // Update transcribed text with analysis
        if result.isFinal {
            let analysis = performSpeechAnalysis()
            transcribedText = formatTranscriptionWithAnalysis(text: currentText, analysis: analysis)
            stopRecording()
        } else {
            // For partial results, show current text without analysis
            transcribedText = currentText
        }
    }

    private func performSpeechAnalysis() -> SpeechMetrics {
        guard let startTime = recordingStartTime else {
            return SpeechMetrics(wpm: 0, averagePauseLength: 0, pauseCount: 0, totalDuration: 0, wordCount: 0)
        }

        let totalDuration = Date().timeIntervalSince(startTime)
        let allText = transcriptionSegments.compactMap { $0.text.isEmpty ? nil : $0.text }.joined(separator: " ")
        let wordCount = allText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count

        // Calculate WPM
        let wpm = totalDuration > 0 ? Int(Double(wordCount) / (totalDuration / 60.0)) : 0

        // Calculate pause statistics
        let pauseSegments = transcriptionSegments.filter { $0.text.isEmpty }
        let pauseCount = pauseSegments.count
        let averagePauseLength = pauseCount > 0 ? pauseSegments.map { $0.duration }.reduce(0, +) / Double(pauseCount) : 0

        return SpeechMetrics(
            wpm: wpm,
            averagePauseLength: averagePauseLength,
            pauseCount: pauseCount,
            totalDuration: totalDuration,
            wordCount: wordCount
        )
    }

    private func formatTranscriptionWithAnalysis(text: String, analysis: SpeechMetrics) -> String {
        return """
        \(text)

        info: \(analysis.formattedString)
        """
    }

    // MARK: - Configuration Methods
    func setPauseThreshold(_ threshold: TimeInterval) {
        pauseThreshold = threshold
    }

    func getCurrentAnalysis() -> SpeechMetrics? {
        guard !transcriptionSegments.isEmpty else { return nil }
        return performSpeechAnalysis()
    }

    // MARK: - Spectrum Analysis Setup
    private func setupSpectrumAnalyzer() {
        // Bind spectrum analyzer data to our published property
        spectrumAnalyzer.$spectrumData
            .receive(on: DispatchQueue.main)
            .assign(to: &$spectrumData)
    }
}
