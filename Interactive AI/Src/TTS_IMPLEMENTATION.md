# Text-to-Speech Implementation Guide

## Overview
This document describes the complete text-to-speech (TTS) implementation for the Interactive AI iOS app. The TTS functionality allows users to convert transcribed text into speech using native iOS Speech Framework voices.

## Architecture

### Core Components

1. **TextToSpeechManager** - Main TTS controller using AVSpeechSynthesizer
2. **TTSControlsView** - UI components for TTS controls
3. **Models** - Data structures for TTS functionality
4. **ConversationViewModel** - Integration with existing conversation flow

## Features

### ✅ Implemented Features

- **Voice Synthesis**: Convert text to speech using native iOS AVSpeechSynthesizer
- **Multiple Voices**: All available iOS system voices (Samantha, Alex, etc.)
- **Speed Control**: Adjustable speech speed (0.0x to 1.0x)
- **Playback Controls**: Play, pause, stop, and mute functionality
- **Error Handling**: Comprehensive error management and user feedback
- **Voice Selection**: Interactive voice picker with system voices
- **Real-time Status**: Loading states and playback indicators

### 🎯 Key Features

#### Voice Options
- **System Voices**: All available iOS system voices
- **Language Support**: Multiple languages based on device settings
- **Voice Quality**: High-quality native iOS speech synthesis
- **Offline Support**: No internet connection required

#### Controls
- **Play/Pause Button**: Start or pause speech playback
- **Stop Button**: Stop current playback
- **Mute Button**: Toggle audio output
- **Speed Slider**: Adjust speech rate (0.25x - 4.0x)
- **Voice Selector**: Choose from available AI voices

## File Structure

```
Src/
├── TextToSpeechManager.swift          # Main TTS controller
├── Services/
│   └── NetworkService.swift          # API communication
├── Models/
│   └── Models.swift                  # TTS data models
├── Views/
│   ├── Components/
│   │   └── TTSControlsView.swift     # TTS UI components
│   └── ConversationView/
│       ├── ConversationView.swift    # Main view (updated)
│       └── ConversationViewModel.swift # View model (updated)
└── TTS_IMPLEMENTATION.md            # This documentation
```

## Usage

### Basic Usage

1. **Record Speech**: Use the microphone button to record speech
2. **View Transcription**: Transcribed text appears in the text area
3. **Play TTS**: Click "Speak Text" button or use TTS controls
4. **Adjust Settings**: Use voice selector and speed slider as needed

### Programmatic Usage

```swift
// Initialize TTS manager
let ttsManager = TextToSpeechManager()

// Synthesize and play text
ttsManager.synthesizeAndPlay(text: "Hello, world!")

// Control playback
ttsManager.pausePlayback()
ttsManager.resumePlayback()
ttsManager.stopPlayback()

// Adjust settings
ttsManager.setVoice(TTSVoice.getAvailableVoices()[0])
ttsManager.setSpeechSpeed(0.5) // 0.0 to 1.0 range
ttsManager.toggleMute()
```

## Native iOS Integration

### Speech Framework

The TTS functionality uses native iOS AVSpeechSynthesizer:

- **AVSpeechSynthesizer**: Main speech synthesis engine
- **AVSpeechUtterance**: Text to be spoken
- **AVSpeechSynthesisVoice**: Voice selection
- **AVSpeechSynthesizerDelegate**: Event handling

### Voice Configuration

```swift
let utterance = AVSpeechUtterance(string: text)
utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
utterance.rate = Float(speechSpeed) // 0.0 to 1.0
utterance.pitchMultiplier = 1.0
utterance.volume = isMuted ? 0.0 : 1.0
```

## Error Handling

### Error Types

- **TTSError.invalidURL**: Invalid API endpoint
- **TTSError.noData**: No response data received
- **TTSError.networkError**: Network connectivity issues
- **TTSError.synthesisFailed**: TTS synthesis failure

### Error Display

- Errors are displayed in the UI with clear messages
- Auto-dismissal after 3 seconds for non-critical errors
- Manual error clearing available through UI controls

## Configuration

### Audio Session Setup

The TTS manager automatically configures the audio session for playback:

```swift
try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
```

### Network Configuration

- Base URL: `http://localhost:3000`
- Timeout: 30 seconds
- Content-Type: `application/json`

## UI Components

### TTSControlsView

Main container for all TTS controls:

- **TTSPlayButtonView**: Play/pause functionality
- **TTSStopButtonView**: Stop playback
- **TTSMuteButtonView**: Mute/unmute audio
- **TTSVoiceSelectorView**: Voice selection
- **TTSSpeedControlView**: Speed adjustment slider

### Integration Points

- **ConversationView**: TTS controls appear when text is transcribed
- **ActionButtonsView**: Quick "Speak Text" button
- **Error Handling**: TTS errors displayed alongside speech recognition errors

## Performance Considerations

### Memory Management

- Audio players are properly deallocated
- Network requests are cancelled when appropriate
- Combine publishers are stored and cleaned up

### Network Optimization

- Requests timeout after 30 seconds
- Audio files are streamed for immediate playback
- Error states prevent unnecessary retries

## Testing

### Manual Testing

1. **Basic Functionality**:
   - Record speech and verify transcription
   - Click "Speak Text" and verify audio playback
   - Test all control buttons (play, pause, stop, mute)

2. **Voice Selection**:
   - Open voice picker and select different voices
   - Verify voice changes are applied

3. **Speed Control**:
   - Adjust speed slider and verify speech rate changes
   - Test extreme values (0.25x, 4.0x)

4. **Error Handling**:
   - Test with backend offline
   - Test with invalid text input
   - Verify error messages are displayed

### Native iOS Testing

No backend server required - TTS works offline using native iOS capabilities.

## Troubleshooting

### Common Issues

1. **No Audio Playback**:
   - Check device volume
   - Verify audio session permissions
   - Check for TTS error messages

2. **Voice Not Available**:
   - Check device language settings
   - Verify voice is installed on device
   - Try different voice selection

3. **Voice Not Changing**:
   - Ensure voice selection is properly saved
   - Check for API response errors
   - Verify voice ID is valid

### Debug Information

Enable debug logging by checking console output for:
- Network request/response details
- Audio session configuration
- Error messages and stack traces

## Future Enhancements

### Planned Features

- **Offline TTS**: Local speech synthesis for offline use
- **Voice Cloning**: Custom voice training
- **SSML Support**: Advanced speech markup
- **Batch Processing**: Multiple text synthesis
- **Audio Effects**: Echo, reverb, pitch adjustment

### Integration Opportunities

- **Conversation History**: Play previous messages
- **AI Responses**: Automatic TTS for AI-generated content
- **Accessibility**: Enhanced voice-over support
- **Multilingual**: Support for multiple languages

## Dependencies

### Required Frameworks

- **AVFoundation**: Audio playback and session management
- **Combine**: Reactive programming and async operations
- **SwiftUI**: User interface components
- **Foundation**: Network requests and data handling

### External Dependencies

- **iOS Speech Framework**: Native AVSpeechSynthesizer
- **Device Voices**: System-installed speech voices

## Conclusion

The TTS implementation provides a comprehensive text-to-speech solution integrated seamlessly with the existing Interactive AI app. Users can easily convert transcribed speech to audio using various AI voices with full playback control and customization options.

The modular architecture ensures maintainability and extensibility for future enhancements while providing a smooth user experience for voice interaction.
