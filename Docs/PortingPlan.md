# Kotlin-to-Swift porting plan

The desktop Kotlin app remains the behavioral reference. Work through these stages in order and verify each slice before expanding the next one. A Swift model alone does not imply that its provider, scanner, or screen is functional.

| Stage | Kotlin source | Native destination | Completion gate | Status |
| --- | --- | --- | --- | --- |
| 1. Shared market contract | `core/model`, scanner `ScanResult` | `MiMiTrends/Sources/Models` | Model fields and defaults are mapped; representative desktop fixtures round-trip; minute-bar and volume rules match | Complete |
| 2. First provider | `finnhub-ws/FinnhubWebSocketClient` | Native Finnhub WebSocket adapter and Keychain credential storage | Desktop test fixtures decode, failures are handled, and a foreground feed can fetch data | Implemented; live account test pending |
| 3. Scanner and storage | `scanner`, `database` | Native scanner services and SQLite repositories | Deterministic signal fixtures agree with desktop; schema and migrations are tested; scans stop outside foreground | Pending |
| 4. Product screens | `charts`, `app` | Adaptive SwiftUI Radar, charts, watchlists, broker import | Real signals are visible on iPhone and iPad; selected Mac workflows work inside App Sandbox | Pending |
| 5. Distribution | Desktop data export and native app | Signed archives and App Store Connect metadata | Data rights, privacy, sandbox, device tests, archive validation, and review access are complete | Pending |

## Stage 1 mapping

- `VolumeStatus` keeps the desktop enum's raw names and aggregation rules. `MinuteBar.isValid` ports `isValidMinuteBar()` from `core/model/MinuteBarValidation.kt`.
- `ProviderInstrument` and `ProviderQuoteSnapshot` preserve provider identity, currency, numeric timestamps, and nullable quote fields. An adapter must supply `updatedAtMillis` explicitly; the desktop constructor's current-time default is not used in a persisted native model.
- `ScanResult` carries the current desktop fields and defaults. The executable-quote, recent-dynamics, entry-quality, analysis-time, and retention values are modeled but have no scanner implementation yet.
- Desktop `Double.NaN` sentinels for unavailable metrics become `nil` at the native adapter boundary. The desktop `entryQualityScore = -1` sentinel also becomes `nil`. This permits normal JSON encoding and prevents unavailable metrics from being mistaken for measured values.
- Tests use the values from the desktop `TestScanResult` helper and representative repository fixtures. They check model behavior and serialization; they are not evidence that a provider or scanner has been ported.

## Next step

Run the Finnhub feed on a device with a user-entered key, including connection failure, Stop, and background transitions. Verify the account's data coverage and display rights before distribution. Then proceed to stage 3: port scanner rules and SQLite persistence, using the trade feed as one input.

## Stage 2 mapping

- `FinnhubTradeDecoder` ports the desktop WebSocket client's `trade` envelope and `s`/`p`/`t`/`v` fields. The fixture is based on its Kotlin unit-test message and also covers multiple trades. Invalid records are skipped, while malformed or rejected messages produce a concise error.
- `FinnhubTradeStream` connects to the same `wss://ws.finnhub.io` endpoint, sends a text subscription, and closes its socket on cancellation. Radar's existing scene lifecycle stops the session outside the foreground. A run identifier rejects late callbacks from an older feed after a new one starts.
- `FinnhubCredentialStore` keeps the user-entered key in the device Keychain. The key is not bundled, placed in UserDefaults, logged, or copied from the desktop configuration.
- The Radar screen displays connection state and received trades solely to verify this provider stage. Signal evaluation, persistence, and full product presentation belong to later stages.
