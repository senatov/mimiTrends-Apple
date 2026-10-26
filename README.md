# MiMiTrends for Apple platforms

This repository is the starting point for a native MiMiTrends application. iOS 27 is the primary platform; macOS 27 is an optional destination. The existing Kotlin/JavaFX desktop application remains in the separate `mimiTrends` repository.

## Current scope

- A shared SwiftUI app target for iPhone, iPad, and Mac.
- Empty Radar, Watchlist, and Settings screens.
- A radar session lifecycle hook that stops scanning whenever the app leaves the foreground.
- An XcodeGen project specification and GitHub Actions build workflow.

The app does **not** yet fetch market data, scan instruments, store a watchlist, import broker data, or show real signals. The Radar screen intentionally says so. No provider credentials or production data are included.

## Build locally

Requires Xcode 27 and XcodeGen.

```sh
xcodegen generate
xcodebuild -project MiMiTrends.xcodeproj -scheme MiMiTrends -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Open `MiMiTrends.xcodeproj` in Xcode to run on an iOS 27 simulator. The same target also supports macOS 27. Physical-device and App Store builds will need a signing team and the relevant App Store configuration.

## Next implementation stages

1. Define shared models for instruments, quotes, and signals, with tests against representative desktop outputs.
2. Port one provider adapter and its decoding, with secure credential storage where applicable.
3. Port scanner rules and SQLite persistence incrementally.
4. Build adaptive radar and chart views, then add watchlists and broker imports.
5. Review provider data rights, privacy disclosures, signing, and sandbox behavior before App Store submission.

Scanning is intended to run only while the app is active. `MiMiTrendsApp` stops the radar session when the scene becomes inactive or enters the background. Provider scanning can later be passed to `RadarSession.start(scan:)`; its task is cancelled by `stop()`.
