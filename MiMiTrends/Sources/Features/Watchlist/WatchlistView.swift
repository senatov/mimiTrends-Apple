import SwiftUI

struct WatchlistView: View {
    let onSelect: (String) -> Void

    @State private var store: WatchlistStore?
    @State private var entries: [WatchlistEntry] = []
    @State private var newSymbol = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Add symbol") {
                    HStack {
                        TextField("Ticker symbol", text: $newSymbol)
                            .autocorrectionDisabled()
                            .onSubmit { Task { await add() } }
                        Button("Add") { Task { await add() } }
                            .disabled(isWorking || newSymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Text("Symbols are saved on this device. A feed starts only when you tap Start on Radar.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }

                Section("Saved symbols") {
                    if store == nil && errorMessage == nil {
                        ProgressView("Loading watchlist")
                    } else if entries.isEmpty {
                        ContentUnavailableView("Watchlist is empty", systemImage: "star")
                    } else {
                        ForEach(entries) { entry in
                            HStack {
                                Button {
                                    onSelect(entry.symbol)
                                } label: {
                                    Label(entry.symbol, systemImage: "waveform.path.ecg")
                                }
                                .accessibilityHint("Show this symbol on Radar")
                                Spacer()
                                Button(role: .destructive) {
                                    Task { await remove([entry.symbol]) }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .disabled(isWorking)
                                .accessibilityLabel("Remove \(entry.symbol)")
                            }
                        }
                        .onDelete { offsets in
                            let symbols = offsets.map { entries[$0].symbol }
                            Task { await remove(symbols) }
                        }
                    }
                }
            }
            .navigationTitle("Watchlist")
            .task { await load() }
        }
    }

    private func load() async {
        guard store == nil else { return }
        do {
            let opened = try await Task.detached(priority: .userInitiated) {
                try WatchlistStore(url: WatchlistStore.defaultURL())
            }.value
            store = opened
            entries = try await opened.load()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func add() async {
        guard let store, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let symbol = try WatchlistStore.normalize(newSymbol)
            let inserted = try await store.add(symbol)
            entries = try await store.load()
            newSymbol = ""
            errorMessage = inserted ? nil : "\(symbol) is already in the watchlist."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove(_ symbols: [String]) async {
        guard let store, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            for symbol in symbols { try await store.remove(symbol) }
            entries = try await store.load()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            if let current = try? await store.load() { entries = current }
        }
    }
}
