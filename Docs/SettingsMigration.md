# Desktop preferences and native Settings

Reviewed the local desktop files in `~/.mimi/trends/` on 2026-10-28. The iPad app cannot read that Mac directory. Supported values below are native first-run defaults; later changes are stored in the app's own container and are never synchronized back to the Kotlin app. Existing native preferences remain authoritative.

| Desktop source | Native handling |
| --- | --- |
| `scanner.properties` rapid crash, rise, sustained move, minimum price, and turnover values | Editable in **Settings → Rapid crashes / Rapid rises / Liquid sustained moves / Shared quality checks**. The eleven recorded values seed native defaults. Saving validates desktop-equivalent bounds, persists locally, and stops an active feed; a new feed takes a stable settings snapshot. |
| `ui-state.properties` selected symbol `ORCL`, chart range `1D` | First-run defaults. Radar and Chart share the selected symbol and chart range, and each change is saved for later launches. The selected tab is also remembered. |
| `scanner.properties` `ui.theme=LIGHT` | Native appearance initially uses Light; Settings offers System, Light, and Dark. The choice is saved locally. The existing compact panel layout corresponds to the old compact density without a separate density switch. |
| `ui-state.properties` divider positions | The native Radar saves wide and stacked divider ratios separately. JavaFX divider coordinates and table columns do not fit both iPad orientations, so they are not copied. |
| `finnhub.properties` API key and webhook secret | Credentials are never copied into source code or UserDefaults. **Settings → Data sources → Manage keys and tokens** edits the active Finnhub API key in its existing Keychain entry. The webhook secret can be saved in a separate Keychain entry for later integration but has no native use today. Each secret field has a reveal button and is masked by default. |
| `scanner.properties` market region, Yahoo symbols, scan interval, statistical anomaly thresholds, table colours, search URL, provider toggles and request intervals | Not exposed as active controls. The current native feed scans one symbol through Finnhub and does not run the desktop's multi-provider, multi-symbol or anomaly scanner. |
| `provider-urls.properties`, `weekly-universe.properties`, `exchange-rate.properties` | No direct native equivalent yet. The single-symbol Finnhub client owns its endpoint. The weekly universe is not the native watchlist. A saved EUR/USD reference rate is not suitable for live price conversion. |
| `window-state.properties` and JavaFX window geometry | Not imported. iPad window management and SwiftUI layout differ from JavaFX. |

Additional named API keys or tokens can be stored in the device Keychain for future source adapters. Such entries do not enable a provider, and no existing desktop secrets are imported automatically. The native watchlist and completed minute bars remain in SQLite, panel ratios and UI choices in device preferences, and all credentials in Keychain. They survive relaunches. Scanner activity itself is deliberately stopped when the app leaves the foreground and is not resumed automatically.
