# WalkingTalking

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" alt="iOS 17.0+">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Xcode-16+-blue.svg" alt="Xcode 16+">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
</p>

A language learning iOS app that helps users practice English pronunciation through **shadowing** and **repetition** techniques.

## ✨ Features

### 🎯 Core Functionality
- **Text-to-Speech Playback** - System speaks each sentence clearly
- **Real-time Speech Recognition** - See what you said as you speak
- **Shadowing Practice** - Speak along with the system (advanced technique)
- **Traditional Practice** - Listen first, then speak
- **Auto-Advance** - Hands-free progression with silence detection

### 🎨 User Interface
- **Karaoke-Style Highlighting** - Current sentence shown in blue
- **Word-Level Feedback** - Green for correct words, red for mistakes
- **Inline Comparison** - See your text directly below the original
- **Scrollable Sentences** - All lesson content in one view
- **Clean Design** - Minimal, focused UI without distractions

### 🧠 Smart Features
- Adaptive silence detection (1.5s threshold)
- Audio session management with interruption handling
- Progress tracking per lesson
- Headphone-friendly (prevents audio feedback)
- Supports both shadowing and traditional learning styles

## 📱 Screenshots

*Coming soon - add screenshots of your app here*

## 🚀 Getting Started

### Requirements
- **iOS 17.0+** (uses SwiftData)
- **Xcode 16+**
- **Swift 5.9+**
- **Headphones recommended** for best experience

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/WalkingTalking.git
   cd WalkingTalking
   ```

2. **Open in Xcode**
   ```bash
   open WalkingTalking.xcodeproj
   ```

3. **Build and Run**
   - Select a simulator or device
   - Press `Cmd + R` to build and run
   - Grant microphone and speech recognition permissions when prompted

## 🎮 How to Use

### First Time Setup
1. Launch the app
2. Grant **Microphone** permission (required)
3. Grant **Speech Recognition** permission (optional but recommended)

### Learning Flow
1. **Select a lesson** from the list
2. **Put on headphones** (prevents audio feedback)
3. **Press play** to start
4. **Choose your style:**
   - **Shadowing**: Speak along with the system
   - **Traditional**: Listen first, then speak
5. **See your results** in green (correct) and red (incorrect) words
6. App auto-advances after 1.5 seconds of silence

## 🏗️ Architecture

### Tech Stack
- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Data persistence (iOS 17+)
- **AVFoundation** - Audio recording and text-to-speech
- **Speech Framework** - Real-time speech recognition
- **MVVM Pattern** - Clean separation of concerns

### Project Structure
```
WalkingTalking/
├── Models/              # SwiftData models (Lesson, Sentence, etc.)
├── ViewModels/          # Business logic (PlayerViewModel)
├── Views/               # SwiftUI views (PlayerView, etc.)
├── Services/            # Audio services (TTS, Recording, etc.)
├── Utilities/           # Constants and helpers
└── Resources/           # Assets and sample data
```

## 📚 Sample Content

The MVP includes a sample lesson: **"6 Minute English - AI and Art"** with 12 sentences about AI's impact on art.

To add your own lessons, modify `LessonDataService.swift`.

## 🧪 Testing

### Run Unit Tests
```bash
# Run all tests
xcodebuild test -scheme WalkingTalking -destination 'platform=iOS Simulator,name=iPhone 17'

# Or use Xcode
# Press Cmd + U
```

### Test Coverage
- Data model logic
- PlayerViewModel state management
- Silence detection
- Navigation controls

## 🔧 Configuration

### Audio Constants
Adjust in `AudioConstants.swift`:
- `silenceDuration` - Time to wait before auto-advance (default: 1.5s)
- `silenceThresholdDB` - Volume threshold for silence detection (default: -40dB)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [Claude Code](https://claude.com/claude-code)
- Inspired by language learning shadowing techniques
- Sample content from BBC Learning English

## 📧 Contact

For questions or feedback, please open an issue on GitHub.

---

**Note**: This is an MVP (Minimum Viable Product). Future enhancements planned:
- Custom lesson creation
- Multiple languages support
- Practice statistics and progress tracking
- Spaced repetition algorithm
- Pronunciation scoring
- Cloud sync via iCloud
