import SwiftUI

struct RadarView: View {
    @Environment(RadarSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("radar.historyLimit.v1") private var maxResults = 30
    @AppStorage("radar.historyAgeHours.v1") private var maxAgeHours = 2
    @AppStorage("radar.scanWatchlist.v1") private var scanWatchlist = false
    @Binding var symbol: String
    @State private var setupMessage: String?
    @State private var recentSignals: [ScanResult] = []
    @State private var selectedSignal: ScanResult?
    @State private var historyError: String?
    @State private var chartRefreshID = 0
    @State private var isPreparingFeed = false
    @State private var discoveryController = DiscoveryPoolController()
    @State private var discoveryStatus: DiscoveryRefreshStatus?
    @State private var discoveryRefreshID: UUID?

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                RadarHeader(
                    symbol: $symbol, scanWatchlist: $scanWatchlist,
                    session: session, setupMessage: setupMessage,
                    isPreparingFeed: isPreparingFeed
                ) {
                    if session.isScanning { session.stop() } else { startFeed() }
                }
                if let activity = currentActivity {
                    RadarActivityBanner(activity: activity)
                }
                RadarWorkspace(
                    signals: { compact in signalList(compact: compact) },
                    sources: { RadarSourcePanel(session: session, discoveryStatus: discoveryStatus) },
                    plot: {
                        RadarChartPreview(
                            symbol: selectedSignal?.symbol ?? symbol,
                            signal: selectedSignal,
                            refreshID: chartRefreshID
                        )
                    }
                )
                .frame(maxHeight: .infinity)
            }
            .padding(8)
            .background(TrendsColors.canvas)
            .navigationTitle("Radar")
            .task(id: "\(maxResults)|\(maxAgeHours)") { await refreshSignals() }
            .task(id: scenePhase) { await refreshDiscoveryWhileActive() }
            .onChange(of: session.lastSignal) { _, latest in
                if latest != nil { Task { await refreshSignals(selectNewest: true) } }
            }
            .onChange(of: session.completedBarsStored) { _, _ in
                chartRefreshID += 1
            }
            .onChange(of: symbol) { _, newValue in
                if selectedSignal?.symbol != newValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
                    selectedSignal = nil
                }
            }
        }
    }

    private func refreshDiscoveryWhileActive() async {
        guard scenePhase == .active else {
            discoveryRefreshID = nil
            await discoveryController.stop()
            return
        }
        var firstRefresh = true
        while !Task.isCancelled {
            let nowMillis = Int64(Date().timeIntervalSince1970 * 1_000)
            let isDue = firstRefresh || discoveryStatus.map { nowMillis >= $0.nextAttemptAtMillis } ?? true
            let refreshID = isDue ? UUID() : nil
            discoveryRefreshID = refreshID
            let status = await discoveryController.refresh()
            if discoveryRefreshID == refreshID { discoveryRefreshID = nil }
            guard !Task.isCancelled else { return }
            discoveryStatus = status
            if isDue {
                AppDiagnostics.shared.record(
                    status.lastAttemptSucceeded ? .info : .warning,
                    "Discovery", "refresh-finished",
                    "candidates=\(status.snapshot?.candidates.count ?? 0) success=\(status.lastAttemptSucceeded) nextAttemptMillis=\(status.nextAttemptAtMillis)"
                )
            }
            firstRefresh = false
            do { try await Task.sleep(for: .seconds(60)) }
            catch { return }
        }
    }

    private var currentActivity: RadarActivity? {
        if isPreparingFeed { return .preparingFeed }
        if session.isScanning && !session.isSubscribed {
            return .connectingFeed(symbolCount: session.targetSymbols.count)
        }
        if discoveryRefreshID != nil {
            return .loadingRankings(previousCount: discoveryStatus?.snapshot?.candidates.count)
        }
        return nil
    }

    private func signalList(compact: Bool) -> some View {
        RadarSignalList(
            signals: recentSignals,
            selected: selectedSignal,
            discoverySnapshot: discoveryStatus?.snapshot,
            compact: compact,
            errorMessage: historyError,
            onSelect: { signal in
                selectedSignal = signal
                symbol = signal.symbol
            },
            onRefresh: { Task { await refreshSignals() } }
        )
    }

    private func refreshSignals(selectNewest: Bool = false) async {
        do {
            let limit = min(max(maxResults, 5), 100)
            let ageHours = min(max(maxAgeHours, 1), 72)
            let cutoff = Int64(Date().timeIntervalSince1970 * 1_000) - Int64(ageHours) * 3_600_000
            let loaded = try await Task.detached(priority: .userInitiated) {
                let store = try MarketSignalStore(url: MarketSignalStore.defaultURL())
                return try await store.loadRecent(limit: limit, sinceEpochMillis: cutoff)
            }.value
            recentSignals = loaded
            AppDiagnostics.shared.record(.info, "Radar", "history-loaded", "signals=\(loaded.count)")
            historyError = nil
            if let selectedSignal, !loaded.contains(where: {
                $0.symbol == selectedSignal.symbol &&
                $0.signalSource == selectedSignal.signalSource &&
                $0.signalEpochMillis == selectedSignal.signalEpochMillis
            }) {
                self.selectedSignal = nil
            }
            if selectNewest, let latest = loaded.first {
                selectedSignal = latest
                symbol = latest.symbol
            } else if selectedSignal == nil {
                let requestedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                selectedSignal = loaded.first { $0.symbol == requestedSymbol }
            }
        } catch {
            historyError = error.localizedDescription
            AppDiagnostics.shared.record(.error, "Radar", "history-failed", "error=\(String(describing: type(of: error)))")
        }
    }

    private func startFeed() {
        guard !isPreparingFeed else { return }
        isPreparingFeed = true
        AppDiagnostics.shared.record(.info, "Radar", "feed-preparing")
        Task { await prepareFeed() }
    }

    @MainActor
    private func prepareFeed() async {
        defer { isPreparingFeed = false }
        setupMessage = nil
        do {
            let selected = symbol
            let includeWatchlist = scanWatchlist
            let watchlist: [WatchlistEntry]
            if includeWatchlist {
                watchlist = try await Task.detached(priority: .userInitiated) {
                    let store = try WatchlistStore(url: WatchlistStore.defaultURL())
                    return try await store.load()
                }.value
            } else {
                watchlist = []
            }
            guard scenePhase == .active else { return }
            let selection = try FinnhubWatchlistSelection(
                selectedSymbol: selected,
                includeWatchlist: includeWatchlist,
                watchlist: watchlist
            )
            guard let key = try FinnhubCredentialStore.load() else {
                setupMessage = FinnhubStreamError.missingKey.localizedDescription
                AppDiagnostics.shared.record(.warning, "Radar", "feed-not-started", "reason=missing-api-key")
                return
            }
            guard scenePhase == .active else { return }
            let scanSettings = RadarScanPreferencesStore.load()
            session.start(symbols: selection.symbols) { [session, scanSettings] runID in
                do {
                    let pipeline = try FinnhubRadarPipeline(settings: scanSettings)
                    let bidAskSampler = FinnhubBidAskSampler()
                    try await FinnhubTradeStream().run(apiKey: key, symbols: selection.symbols) {
                        await session.markSubscribed(runID: runID)
                    } onTrade: { trade in
                        let nowEpochSeconds = Int64(Date().timeIntervalSince1970)
                        let quote = await bidAskSampler.latest(
                            symbol: trade.symbol, apiKey: key, nowMillis: nowEpochSeconds * 1_000
                        )
                        let update = try await pipeline.accept(
                            trade, nowEpochSeconds: nowEpochSeconds,
                            quote: quote, marketCurrency: "USD"
                        )
                        if update.storedBar {
                            await session.recordStoredBar(runID: runID)
                        }
                        if update.storedSignal, let signal = update.signal {
                            await session.recordSignal(signal, runID: runID)
                        }
                        await session.record(trade, runID: runID)
                    }
                } catch is CancellationError {
                    // The scene lifecycle or Stop button ended the feed.
                } catch {
                    await session.recordFailure(error.localizedDescription, runID: runID)
                }
            }
        } catch {
            setupMessage = error.localizedDescription
            AppDiagnostics.shared.record(.error, "Radar", "feed-setup-failed", "error=\(String(describing: type(of: error)))")
        }
    }
}
