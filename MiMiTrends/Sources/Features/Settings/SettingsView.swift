import SwiftUI

struct SettingsView: View {
    @AppStorage("settings.section.v1") private var selectedSection = SettingsSection.scanner.rawValue

    private var sectionSelection: Binding<String?> {
        Binding(
            get: { selectedSection },
            set: { if let section = $0 { selectedSection = section } }
        )
    }

    var body: some View {
        NavigationSplitView {
            List(selection: sectionSelection) {
                Section("Preferences") {
                    ForEach(SettingsSection.allCases) { section in
                        NavigationLink(value: section.rawValue) {
                            Label(section.title, systemImage: section.symbol)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            switch SettingsSection(rawValue: selectedSection) ?? .scanner {
            case .scanner:
                ScannerSettingsView()
            case .rapidMoves:
                RadarScanSettingsView()
            case .providers:
                SourceCredentialsView()
            case .appearance:
                AppearanceSettingsView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case scanner, rapidMoves, providers, appearance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scanner: "Scanner"
        case .rapidMoves: "Rapid moves"
        case .providers: "Market data providers"
        case .appearance: "Appearance"
        }
    }

    var symbol: String {
        switch self {
        case .scanner: "line.3.horizontal.decrease.circle"
        case .rapidMoves: "waveform.path.ecg"
        case .providers: "antenna.radiowaves.left.and.right"
        case .appearance: "paintpalette"
        }
    }
}
