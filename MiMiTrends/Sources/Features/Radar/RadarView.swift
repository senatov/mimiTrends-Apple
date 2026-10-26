import SwiftUI

struct RadarView: View {
    @Environment(RadarSession.self) private var session
    @State private var symbol = "AAPL"
    @State private var setupMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Finnhub live trades") {
                    TextField("Symbol", text: $symbol)

                    Button(session.isScanning ? "Stop live feed" : "Start live feed") {
                        if session.isScanning {
                            session.stop()
                        } else {
                            startFeed()
                        }
                    }
                    .disabled(!session.isScanning && symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Text("A Finnhub API key is required in Settings. The connection closes when the app leaves the foreground.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Connection") {
                    LabeledContent("Status", value: session.isScanning ? (session.isSubscribed ? "Subscribed" : "Connecting") : "Stopped")
                    LabeledContent("Trades received", value: "\(session.tradeCount)")
                    LabeledContent("Completed bars stored", value: "\(session.completedBarsStored)")
                    if let trade = session.lastTrade {
                        LabeledContent("Last trade", value: "\(trade.symbol) · \(trade.price.formatted())")
                    }
                    if let signal = session.lastSignal {
                        LabeledContent(signal.signalSource, value: "\(signal.windowChangePercent.formatted())%")
                    }
                    if let message = setupMessage ?? session.errorMessage {
                        Text(message).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Radar")
        }
    }

    private func startFeed() {
        setupMessage = nil
        do {
            guard let key = try FinnhubCredentialStore.load() else {
                setupMessage = FinnhubStreamError.missingKey.localizedDescription
                return
            }
            let requestedSymbol = symbol
            session.start { [session] runID in
                do {
                    let pipeline = try FinnhubRadarPipeline()
                    try await FinnhubTradeStream().run(apiKey: key, symbol: requestedSymbol) {
                        await session.markSubscribed(runID: runID)
                    } onTrade: { trade in
                        let update = try await pipeline.accept(
                            trade, nowEpochSeconds: Int64(Date().timeIntervalSince1970)
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
