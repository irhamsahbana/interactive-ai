//
//  ConversationHistoryView.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import SwiftUI

struct ConversationHistoryView: View {
    var viewModel: ConversationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.conversations.isEmpty {
                Text("Conversation History")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.conversations) { message in
                            ConversationMessageView(message: message)
                        }

                        // Show processing indicator
                        if viewModel.isProcessingAI {
                            AIProcessingView()
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 300)
            }
        }
    }
}

struct ConversationMessageView: View {
    let message: ConversationMessage

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                MessageBubbleView(
                    text: message.content,
                    isFromUser: true,
                    timestamp: message.timestamp
                )
            } else {
                MessageBubbleView(
                    text: message.content,
                    isFromUser: false,
                    timestamp: message.timestamp
                )
                Spacer()
            }
        }
    }
}

struct MessageBubbleView: View {
    let text: String
    let isFromUser: Bool
    let timestamp: Date

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
            Text(text)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isFromUser ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isFromUser ? .white : .primary)
                .frame(maxWidth: 250, alignment: isFromUser ? .trailing : .leading)

            Text(timeFormatter.string(from: timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct AIProcessingView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            Text("AI is thinking")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .opacity(animationPhase == index ? 1.0 : 0.3)
                }
            }
            .onAppear {
                startAnimation()
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

#Preview {
    ConversationHistoryView(viewModel: ConversationViewModel())
}
