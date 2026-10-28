# Dynamic scan pool: desktop behavior and native port

The desktop screenshot shows three different counts: the full candidate pool, the symbols eligible for the current market scan, and the number already analyzed in this cycle. They must remain separate in the native Radar. The current Apple app can request one manually selected Finnhub symbol or that symbol plus up to four saved watchlist symbols. Its watchlist is not a dynamic discovery pool, and requested subscriptions are not a count of analyzed symbols.

## Desktop reference

1. `WallstreetOnlineRankingPages` defines 18 ranking pages across top performers, flops, most traded, gaps, reversals, high range, and regional indices. The example [Top Aktien Performance](https://www.wallstreet-online.de/statistik/top-aktien-performance) ranks price performance; [Top Handelsvolumen](https://www.wallstreet-online.de/statistik/top-aktien-meistgehandelt) is the distinct turnover ranking. A performance list must not be labelled a liquidity list.
2. `WallstreetOnlineMarketDataClient.loadRankings()` fetches the pages with bounded concurrency and interleaves their first 50 rows. `WallstreetOnlineDiscoveryService` interleaves categories, selects at most 40 unique instrument paths, resolves company names to symbols through Yahoo search, and caches successful discovery for 30 minutes. A failed refresh retains the previous snapshot and retries after five minutes.
3. `MainController` joins the weekly universe with wallstreetONLINE discovery. `DynamicMarketUniverse` combines those discovered symbols with a configured core and pinned watchlist. It scores discovery rank and observed activity, caps each US/European region at 200 symbols, and limits replacements to five per refresh. Its selection snapshot lasts 30 minutes.
4. `ScanCycleCoordinator` filters the pool for currently active markets, orders the eligible symbols, requests provider data, updates live source telemetry, and reports completed/eligible/pool counts. The ranking pages only select candidates; they do not themselves provide a live executable quote or minute-bar stream.

The old code paths are `market-data/.../WallstreetOnlineRanking.kt`, `WallstreetOnlineMarketDataClient.kt`, `app/.../company/WallstreetOnlineDiscoveryService.kt`, `app/.../scanner/DynamicMarketUniverse.kt`, and `app/.../ui/ScanCycleCoordinator.kt`. Treat these as behavioral references, not as code to copy wholesale into SwiftUI.

## Native implementation sequence

1. Define a provider-independent candidate record with a stable instrument identifier, source category, rank, observation time, and optional resolved ticker. Keep source parsing, ticker resolution, pool selection, quote collection, and signal detection in separate services. Reject unresolved or ambiguous names instead of guessing a ticker.
2. Add a bounded discovery adapter behind a provider interface, with fixture tests for the source's current HTML or licensed API shape. Fetch only while the app is active, cache for 30 minutes, retain the last good pool on failure, and back off after errors. Deduplicate instruments across ranking categories and verify their exchange/currency before scanning.
3. Merge discovered symbols with user-pinned symbols and a stable core. Bound the total pool, per-source work, provider subscriptions, and replacements per refresh. Persist the last successful pool and its provenance locally; never mistake an old snapshot for live source health.
4. Add a market-hours and provider-capability gate, then a foreground multi-symbol scan coordinator. Keep source coverage, pool size, eligible count, processed count, last successful refresh, and errors as separate telemetry. Stop all network work when the scene becomes inactive or enters the background.
5. Port live source panels and selected-signal chart behavior. Show each source only when its adapter actually runs. Validate signal semantics against desktop fixtures and fresh device runs before calling the Radar equivalent to the prototype.

The bounded Finnhub Watchlist feed is insufficient for this pool: a public ranking page returns company names and website instrument paths, while a market feed needs exact provider symbols, exchange coverage, subscription capacity, and minute history. The watchlist path assumes user-entered provider tickers and excludes names needing resolution; it does not prove that the account receives trades for every requested ticker. The Apple app must validate ranking mappings and account limits before subscribing to discovered symbols. The desktop's Yahoo, Tradegate, and Euronext paths do not become available merely by saving their keys or URLs.

## Distribution boundary

The ranking pages are a discovery input, not a grant to redistribute their market data. Before shipping automated ingestion in an App Store build, confirm the source's terms and any required data agreement for this use, and confirm the quote provider's display and redistribution rights. The current wallstreetONLINE page notes delayed exchange prices; do not present its ranking price as a live quote. Keep the discovery adapter replaceable so a licensed feed can supply the same candidate model.
