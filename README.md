# MiMiTrends for Apple platforms

This repository is the starting point for a native MiMiTrends application. iOS 27 is the primary platform; macOS 27 is an optional destination. The existing Kotlin/JavaFX desktop application remains in the separate `mimiTrends` repository.

## Current scope

- A shared SwiftUI app target for iPhone, iPad, and Mac.
- A Radar screen that can show a Finnhub WebSocket trade feed for one entered symbol, plus a Keychain-backed API key setting. Watchlist remains a placeholder.
- A radar session lifecycle hook that stops scanning whenever the app leaves the foreground.
- Shared market models for provider instruments, quotes, minute bars, and scan results.
- An XcodeGen project specification and GitHub Actions build workflow.

The app can receive Finnhub trades while it is active, save completed minute bars, and detect one close-confirmed rapid-rise signal. It does **not** yet implement the full desktop scanner, store a watchlist, import broker data, or show charts. No provider credentials or production data are included.

To try the feed, enter your own Finnhub API key under Settings, then enter a symbol on Radar and tap **Start live feed**. The key stays in this device's Keychain and can be removed in Settings. Completed minute bars are stored in the app container; the current unfinished minute is discarded when the feed stops. The feed stops when the app leaves the foreground. Availability of symbols and trade updates depends on the Finnhub account, exchange coverage, and market hours.

## Run from the command line

Requires Xcode 27 with an iOS 27 Simulator runtime. XcodeGen is needed only to regenerate the checked-in Xcode project (`brew install xcodegen`). Run the commands below from the repository root:

```zsh
zsh Scripts/run_ios.zsh
```

This builds, boots an iPhone 18 Pro simulator, installs the app, and launches it. The script opens the Simulator window when the GUI app is installed; the command-line launch also works without that window. Set `SIMULATOR_UDID` to use another installed iOS 27 simulator.

| Script | Purpose |
| --- | --- |
| `zsh Scripts/generate_project.zsh` | Regenerate `MiMiTrends.xcodeproj` from `project.yml` after changing project settings or files. |
| `zsh Scripts/build_ios.zsh` | Build an ad hoc signed Debug app for iOS Simulator without launching it. Pass `Release` for a Release configuration simulator build. |
| `zsh Scripts/run_ios.zsh` | Build, boot, install, and launch on an iOS 27 simulator. |
| `zsh Scripts/test_ios.zsh` | Boot an iOS 27 simulator and run the unit tests locally; CI lets Xcode select and start the simulator. |
| `zsh Scripts/build_macos.zsh` | Build the optional unsigned macOS app. Pass `Release` for a Release configuration build. |
| `zsh Scripts/run_macos.zsh` | Build, ad hoc sign with the Mac App Sandbox entitlements, and launch on macOS 27 or newer. |
| `zsh Scripts/check_macos_sandbox.zsh` | Check the Mac target's sandbox entitlement file and Xcode build settings. |

All builds use this repository's ignored `DerivedData/` directory. They do not clear shared Xcode caches, modify other repositories, sign an App Store distribution binary, or upload one. iOS Simulator builds use local ad hoc signing so Keychain works during development. `run_macos.zsh` signs its local Debug app only to exercise the sandbox during development. The generated Xcode project is committed so it can also be opened directly in Xcode.

## App Store preparation

The current app is a development skeleton and is **not ready for App Review**: its main screens intentionally have no market functionality. Apple's [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) require a complete, useful app, and the Mac App Store also requires sandboxing and Xcode-based packaging.

- The macOS target uses [App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox) with outgoing network access and read-only access to user-selected import files. It requests no unrestricted folder or incoming network access. See [Storage and desktop data migration](Docs/DataStorage.md) for the planned container layout and migration rules.
- The iOS and macOS apps use SwiftUI and system APIs; the former JVM/JavaFX runtime is not bundled.
- The native app uses `org.senatov.mimitrends.apple` on both platforms so it can coexist with the existing macOS JVM app.
- The scripts produce local simulator and Mac development builds. For App Store distribution, configure a development team, archive with Xcode, validate the archive, and submit through App Store Connect. Local ad hoc signing is not evidence of App Store approval. See Apple's [distribution guide](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases).
- Before submission, complete the market features, confirm that the Finnhub agreement permits the intended App Store distribution and display of market data, review privacy disclosures, test on supported devices, and provide any account or demo access required for review. [Finnhub lists commercial use and redistribution rights separately](https://api.finnhub.io/pricing-startups-and-enterprise) from personal-use plans; a user-supplied API key does not itself establish distribution rights.

## Next implementation stages

Progress and completion gates are tracked in [the porting plan](Docs/PortingPlan.md).

1. Define shared models for instruments, quotes, and signals, with tests against representative desktop outputs.
2. Port one provider adapter and its decoding, with secure credential storage where applicable.
3. Port scanner rules and SQLite persistence incrementally.
4. Build adaptive radar and chart views, then add watchlists and broker imports.
5. Validate signed iOS and macOS archives, provider data rights, privacy disclosures, and sandbox behavior before App Store submission.

Scanning is intended to run only while the app is active. `MiMiTrendsApp` stops the radar session when the scene becomes inactive or enters the background. Provider scanning can later be passed to `RadarSession.start(scan:)`; its task is cancelled by `stop()`.
