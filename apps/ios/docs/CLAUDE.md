# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WalkingTalking is an iOS application built with SwiftUI and SwiftData. This is a standard Xcode project with a SwiftData-based architecture for data persistence.

## Architecture

**Data Layer**
- Uses SwiftData framework for persistence (iOS 17+)
- Data models are defined with the `@Model` macro (e.g., `Item.swift`)
- The `ModelContainer` is configured in `WalkingTalkingApp.swift` and injected into the view hierarchy
- SwiftData schema is defined at app startup with persistent storage enabled by default

**UI Layer**
- SwiftUI-based interface following NavigationSplitView pattern
- Views access data through `@Environment(\.modelContext)` and `@Query` property wrappers
- `ContentView.swift` demonstrates list-detail navigation pattern with CRUD operations

**App Structure**
- Entry point: `WalkingTalkingApp.swift` with `@main` attribute
- Main view: `ContentView.swift`
- Data models: Located in `WalkingTalking/` directory (e.g., `Item.swift`)

## Build & Test Commands

**Building the app:**
```bash
# Build for generic iOS device
xcodebuild -scheme WalkingTalking -destination 'generic/platform=iOS' build

# Build and run in simulator (iPhone 15 Pro)
xcodebuild -scheme WalkingTalking -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Or use Xcode directly
open WalkingTalking.xcodeproj
```

**Running tests:**
```bash
# Run all tests
xcodebuild test -scheme WalkingTalking -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test target
xcodebuild test -scheme WalkingTalking -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:WalkingTalkingTests

# Run single test class
xcodebuild test -scheme WalkingTalking -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:WalkingTalkingTests/WalkingTalkingTests

# Run single test method
xcodebuild test -scheme WalkingTalking -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:WalkingTalkingTests/WalkingTalkingTests/testExample
```

**Clean build:**
```bash
xcodebuild clean -scheme WalkingTalking
```

## Available Targets

- **WalkingTalking**: Main application target
- **WalkingTalkingTests**: Unit tests
- **WalkingTalkingUITests**: UI/integration tests

## Swift & iOS Version

This project uses SwiftData, which requires iOS 17.0+ and Swift 5.9+. The project uses modern Swift features including macros (`@Model`, `@main`) and property wrappers (`@Query`, `@Environment`).
