//
//  SpectrumVisualizationView.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import SwiftUI

struct SpectrumVisualizationView: View {
    let spectrumData: SpectrumData?
    let isRecording: Bool

    @State private var animationPhase: Double = 0

    private let barCount = 32
    private let barWidth: CGFloat = 8
    private let barSpacing: CGFloat = 2
    private let maxBarHeight: CGFloat = 60
    private let minBarHeight: CGFloat = 4

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                SpectrumBar(
                    magnitude: getMagnitude(for: index),
                    maxHeight: maxBarHeight,
                    minHeight: minBarHeight,
                    width: barWidth,
                    animationPhase: animationPhase,
                    index: index
                )
            }
        }
        .frame(height: maxBarHeight + 10)
        .onAppear {
            startAnimation()
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }

    private func getMagnitude(for index: Int) -> Float {
        guard let spectrumData = spectrumData,
              index < spectrumData.magnitudes.count else {
            return 0.0
        }
        return spectrumData.magnitudes[index]
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }

    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            animationPhase = 0.0
        }
    }
}

struct SpectrumBar: View {
    let magnitude: Float
    let maxHeight: CGFloat
    let minHeight: CGFloat
    let width: CGFloat
    let animationPhase: Double
    let index: Int

    @State private var currentHeight: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: width / 2)
            .fill(barColor)
            .frame(width: width, height: currentHeight)
            .onChange(of: magnitude) { _, newMagnitude in
                updateHeight(newMagnitude)
            }
            .onChange(of: animationPhase) { _, newPhase in
                updateHeight(magnitude)
            }
    }

    private var barColor: Color {
        let normalizedMagnitude = CGFloat(magnitude)

        if normalizedMagnitude < 0.3 {
            return Color.blue.opacity(0.6)
        } else if normalizedMagnitude < 0.6 {
            return Color.green.opacity(0.7)
        } else if normalizedMagnitude < 0.8 {
            return Color.orange.opacity(0.8)
        } else {
            return Color.red.opacity(0.9)
        }
    }

    private func updateHeight(_ magnitude: Float) {
        let targetHeight = minHeight + (maxHeight - minHeight) * CGFloat(magnitude)

        // Add some randomness and animation delay based on index
        let delay = Double(index) * 0.02
        let randomFactor = 0.8 + 0.4 * sin(animationPhase * .pi * 2 + Double(index) * 0.5)

        let animatedHeight = targetHeight * CGFloat(randomFactor)

        withAnimation(.easeInOut(duration: 0.1).delay(delay)) {
            currentHeight = max(minHeight, animatedHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("Spectrum Visualization")
            .font(.headline)

        SpectrumVisualizationView(
            spectrumData: SpectrumData(
                magnitudes: (0..<32).map { _ in Float.random(in: 0...1) },
                frequencies: (0..<32).map { Float($0 * 100) }
            ),
            isRecording: true
        )
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)

        Text("Recording...")
            .foregroundColor(.red)
    }
    .padding()
}
