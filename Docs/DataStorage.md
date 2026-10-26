# Storage and desktop data migration

The Kotlin desktop app currently stores its SQLite database and Java properties files under `~/.mimi/trends/`. The native Apple app uses a different bundle identifier and each installation has its own sandbox container. It must never assume that the desktop path is writable or available, especially on iPhone.

## What can be reused

| Desktop data | Native Apple approach |
| --- | --- |
| `mimitrends.db` | Keep SQLite as the import format. Port the schema migrations and SQL behavior to a native SQLite access layer before opening desktop data. Copy an integrity-checked snapshot into the app's Application Support directory; do not operate on the desktop app's live database. |
| `scanner.properties`, `provider-urls.properties`, `weekly-universe.properties` | Import supported keys selectively, validate values, and save native preferences. The `.properties` files are migration inputs, not the native app's permanent configuration format. |
| `ui-state.properties`, `window-state.properties` | Translate only portable preferences such as a selected symbol or chart range. JavaFX window coordinates, table columns, and divider positions do not map directly to iPhone layouts. |
| `finnhub.properties` and `.env` | Never copy credentials into ordinary app configuration. Ask the user to enter keys again or import them deliberately into Keychain. Do not log, bundle, or commit them. |
| `exchange-rate.properties` and downloaded market history | Treat data that can be fetched again as cache. Do not mix it with user-created portfolio or watchlist data in a purgeable location. |

The desktop database currently uses WAL mode and contains both reconstructible market data and durable user data such as broker trades. A live `mimitrends.db` file alone may omit recent transactions still in its WAL file. Migration should start from a consistent SQLite backup or `VACUUM INTO` snapshot made by the desktop app, check its integrity and `schema_migrations`, then import it into a new native-owned database. The existing database schema is currently at migration 21; that number must be checked again when migration code is implemented.

## Native storage locations

- **Application Support:** user-created watchlists, imported trades, durable settings, and their database. Resolve the directory with Foundation's `FileManager` API inside the app container. These records should survive normal cache cleanup and backup.
- **Caches:** downloaded quotes, logos, and market history that the app can obtain again. The system may remove these files. If a future database still mixes durable and cache data, do not put the entire database in Caches or exclude the entire file from backup; split the data first.
- **UserDefaults:** small nonsecret preferences that fit native settings. Keep a versioned mapping from supported Java properties keys for one-time import.
- **Keychain:** API keys and other credentials.

Each iPhone, iPad, and Mac installation has its own container. A common source schema does not synchronize the database between devices. Decide on iCloud or a service only if cross-device synchronization becomes a product requirement.

## Sandbox access

The macOS target enables App Sandbox, outgoing network connections for market providers, and read-only access to files the user explicitly selects for import. It does not request incoming connections, unrestricted home-folder access, or write access to selected files. Use `fileImporter` for desktop database, settings, or broker CSV import; copy selected data into the container and release any security-scoped access after the import. iOS document selection also yields security-scoped URLs. Additional entitlements should be added only when a feature needs them.

The build and test scripts produce unsigned binaries. `run_macos.zsh` ad hoc signs its local Debug build with the declared sandbox entitlements so the development launch exercises the sandbox. This does not test App Store distribution signing or prove that every future file and network operation works. Before distribution, run the completed workflows in a distribution-signed sandboxed build and validate the archive in Xcode.
