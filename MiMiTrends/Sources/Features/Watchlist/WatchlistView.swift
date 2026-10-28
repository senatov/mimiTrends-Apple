import SwiftUI
import UniformTypeIdentifiers

struct WatchlistView: View {
    let onSelect: (String) -> Void

    @State private var store: WatchlistStore?
    @State private var entries: [WatchlistEntry] = []
    @State private var newSymbol = ""
    @State private var errorMessage: String?
    @State private var isWorking = false
    @State private var showingImporter = false
    @State private var importMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Watchlist").font(.title2.weight(.semibold))
                        Text("\(entries.count) saved symbols on this device")
                            .font(.caption).foregroundStyle(.secondary)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) { addControls }
                            VStack(alignment: .leading, spacing: 10) { addControls }
                        }
                        Text("Selecting a symbol opens Radar. The feed starts only when you tap Start there.")
                            .font(.footnote).foregroundStyle(.secondary)
                        TrendsActionButton(
                            title: "Import desktop watchlist",
                            systemImage: "square.and.arrow.down",
                            tint: .teal
                        ) { showingImporter = true }
                        .disabled(isWorking || store == nil)
                        if let importMessage {
                            Text(importMessage).font(.footnote).foregroundStyle(.secondary)
                        }
                        if let errorMessage {
                            Text(errorMessage).font(.footnote).foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .trendsPanel()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section("Saved symbols") {
                    if store == nil && errorMessage == nil {
                        ProgressView("Loading watchlist")
                    } else if entries.isEmpty {
                        ContentUnavailableView("Watchlist is empty", systemImage: "star")
                    } else {
                        ForEach(entries) { entry in
                            WatchlistEntryRow(entry: entry, isWorking: isWorking) {
                                onSelect(entry.symbol)
                            } onRemove: {
                                Task { await remove([entry.symbol]) }
                            }
                        }
                        .onDelete { offsets in
                            let symbols = offsets.map { entries[$0].symbol }
                            Task { await remove(symbols) }
                        }
                    }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .background(Color.secondary.opacity(0.04))
            .navigationTitle("Watchlist")
            .task { await load() }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                if case .success(let url) = result {
                    Task { await importSnapshot(at: url) }
                } else if case .failure(let error) = result {
                    importMessage = error.localizedDescription
                }
            }
        }
    }

    @ViewBuilder
    private var addControls: some View {
        TextField("Ticker symbol", text: $newSymbol)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .frame(maxWidth: 240)
            .onSubmit { Task { await add() } }
        TrendsActionButton(title: "Add", systemImage: "plus", tint: .green) {
            Task { await add() }
        }
        .disabled(isWorking || newSymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private func importSnapshot(at url: URL) async {
        guard let store, !isWorking else { return }
        isWorking = true
        importMessage = nil
        defer { isWorking = false }
        do {
            let summary = try await DesktopWatchlistImporter.importSnapshot(at: url, into: store)
            entries = try await store.load()
            importMessage = "Imported \(summary.entryCount) symbols; \(summary.insertedCount) added. Existing symbols were kept."
            errorMessage = nil
        } catch {
            importMessage = error.localizedDescription
        }
    }
}
