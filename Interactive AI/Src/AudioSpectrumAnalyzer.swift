//
//  AudioSpectrumAnalyzer.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import AVFoundation
import Accelerate
import SwiftUI

// MARK: - Spectrum Data Models
struct SpectrumData {
    let magnitudes: [Float]
    let frequencies: [Float]
    let timestamp: Date

    init(magnitudes: [Float], frequencies: [Float]) {
        self.magnitudes = magnitudes
        self.frequencies = frequencies
        self.timestamp = Date()
    }
}

// MARK: - Audio Spectrum Analyzer
class AudioSpectrumAnalyzer: ObservableObject {
    @Published var spectrumData: SpectrumData?
    @Published var isAnalyzing = false

    // FFT Configuration
    private let fftSize: Int = 1024
    private let numberOfBins: Int = 32
    private let sampleRate: Float = 44100.0

    // FFT Setup
    private var fftSetup: FFTSetup
    private var realBuffer: [Float]
    private var imaginaryBuffer: [Float]
    private var window: [Float]

    // Audio Processing
    private var audioBuffer: [Float] = []
    private let bufferSize: Int = 1024

    init() {
        // Initialize FFT setup
        let log2n = vDSP_Length(log2(Double(fftSize)))
        fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))!

        // Initialize buffers
        realBuffer = [Float](repeating: 0, count: fftSize / 2)
        imaginaryBuffer = [Float](repeating: 0, count: fftSize / 2)

        // Create Hann window for better frequency analysis
        window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))

        // Initialize audio buffer
        audioBuffer = [Float](repeating: 0, count: bufferSize)
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    // MARK: - Audio Processing
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else {
            return
        }

        let frameCount = Int(buffer.frameLength)

        // Copy audio data to our buffer
        if frameCount >= bufferSize {
            // Use the latest samples
            let startIndex = frameCount - bufferSize
            for i in 0..<bufferSize {
                audioBuffer[i] = channelData[startIndex + i]
            }
        } else {
            // Shift existing data and append new data
            let shiftAmount = bufferSize - frameCount
            for i in 0..<shiftAmount {
                audioBuffer[i] = audioBuffer[i + frameCount]
            }
            for i in 0..<frameCount {
                audioBuffer[shiftAmount + i] = channelData[i]
            }
        }

        // Apply window function
        var windowedData = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(audioBuffer, 1, window, 1, &windowedData, 1, vDSP_Length(fftSize))

        // Prepare data for FFT (interleaved format)
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)

        realBuffer.withUnsafeMutableBufferPointer { realBufferPointer in
            imaginaryBuffer.withUnsafeMutableBufferPointer { imagBufferPointer in
                var splitComplex = DSPSplitComplex(realp: realBufferPointer.baseAddress!, imagp: imagBufferPointer.baseAddress!)

                // Perform FFT
                windowedData.withUnsafeMutableBufferPointer { bufferPointer in
                    vDSP_ctoz(UnsafePointer<DSPComplex>(OpaquePointer(bufferPointer.baseAddress!)), 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
                }

                vDSP_fft_zrip(fftSetup, &splitComplex, 1, vDSP_Length(log2(Double(fftSize))), Int32(FFT_FORWARD))

                // Calculate magnitudes
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
            }
        }

        // Convert to dB scale and normalize
        var dbMagnitudes = [Float](repeating: 0, count: fftSize / 2)
        var zeroReference: Float = 1.0
        vDSP_vdbcon(magnitudes, 1, &zeroReference, &dbMagnitudes, 1, vDSP_Length(fftSize / 2), 0)

        // Normalize to 0-1 range
        var minVal: Float = 0
        var maxVal: Float = 0
        vDSP_minv(dbMagnitudes, 1, &minVal, vDSP_Length(fftSize / 2))
        vDSP_maxv(dbMagnitudes, 1, &maxVal, vDSP_Length(fftSize / 2))

        let range = maxVal - minVal
        if range > 0 {
            vDSP_vsadd(dbMagnitudes, 1, [-minVal], &dbMagnitudes, 1, vDSP_Length(fftSize / 2))
            vDSP_vsdiv(dbMagnitudes, 1, [range], &dbMagnitudes, 1, vDSP_Length(fftSize / 2))
        }

        // Downsample to number of bins
        let binSize = (fftSize / 2) / numberOfBins
        var downsampledMagnitudes = [Float](repeating: 0, count: numberOfBins)
        var frequencies = [Float](repeating: 0, count: numberOfBins)

        for i in 0..<numberOfBins {
            let startIndex = i * binSize
            let endIndex = min(startIndex + binSize, fftSize / 2)

            // Average the magnitudes in this bin
            var sum: Float = 0
            for j in startIndex..<endIndex {
                sum += dbMagnitudes[j]
            }
            downsampledMagnitudes[i] = sum / Float(endIndex - startIndex)

            // Calculate center frequency for this bin
            let centerIndex = startIndex + binSize / 2
            frequencies[i] = Float(centerIndex) * sampleRate / Float(fftSize)
        }

        // Update spectrum data on main thread
        DispatchQueue.main.async { [weak self] in
            self?.spectrumData = SpectrumData(magnitudes: downsampledMagnitudes, frequencies: frequencies)
        }
    }

    func startAnalysis() {
        isAnalyzing = true
    }

    func stopAnalysis() {
        isAnalyzing = false
        spectrumData = nil
    }
}
