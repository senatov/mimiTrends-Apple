import SwiftUI

struct RadarView: View {
    @Environment(RadarSession.self) private var session
    @AppStorage("radar.historyLimit.v1") private var maxResults = 30
    @AppStorage("radar.historyAgeHours.v1") private var maxAgeHours = 2
    @Binding var symbol: String
    @State private var setupMessage: String?
    @State private var recentSignals: [ScanResult] = []
    @State private var selectedSignal: ScanResult?
    @State private var historyError: String?
    @State private var chartRefreshID = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                RadarHeader(symbol: $symbol, session: session, setupMessage: setupMessage) {
                    if session.isScanning { session.stop() } else { startFeed() }
                }
                RadarWorkspace(
                    signals: { compact in signalList(compact: compact) },
                    sources: { RadarSourcePanel(session: session) },
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
            .navigationTitle(AppIdentity.windowTitle)
            .task(id: "\(maxResults)|\(maxAgeHours)") { await refreshSignals() }
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

    private func signalList(compact: Bool) -> some View {
        RadarSignalList(
            signals: recentSignals,
            selected: selectedSignal,
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
        }
    }

    private func startFeed() {
        setupMessage = nil
        do {
            let scanSettings = RadarScanPreferencesStore.load()
            guard let key = try FinnhubCredentialStore.load() else {
                setupMessage = FinnhubStreamError.missingKey.localizedDescription
                return
            }
            let requestedSymbol = symbol
            session.start { [session, scanSettings] runID in
                do {
                    let pipeline = try FinnhubRadarPipeline(settings: scanSettings)
                    let bidAskSampler = FinnhubBidAskSampler()
                    try await FinnhubTradeStream().run(apiKey: key, symbol: requestedSymbol) {
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
                        if let signal = update.signal {
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
        }
    }
}
