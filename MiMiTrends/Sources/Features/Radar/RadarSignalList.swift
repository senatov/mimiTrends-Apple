import SwiftUI

struct RadarSignalList: View {
    let signals: [ScanResult]
    let selected: ScanResult?
    let compact: Bool
    let errorMessage: String?
    let onSelect: (ScanResult) -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Live radar").font(.headline)
                    Text("Recent saved detections")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh", systemImage: "arrow.clockwise", action: onRefresh)
                    .labelStyle(.iconOnly)
                    .buttonStyle(TrendsActionButtonStyle(compact: true))
                    .accessibilityLabel("Refresh saved signals")
            }
            Divider()
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
            if signals.isEmpty {
                ContentUnavailableView(
                    "No saved signals",
                    systemImage: "waveform.path.ecg",
                    description: Text("Confirmed moves will appear after a foreground scan finds one.")
                )
                .frame(minHeight: 180)
            } else {
                if !compact {
                    HStack(spacing: 8) {
                        Text("Symbol").frame(width: 80, alignment: .leading)
                        Text("Event").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Movement").frame(width: 115, alignment: .trailing)
                        Text("Price").frame(width: 70, alignment: .trailing)
                        Text("Age").frame(width: 95, alignment: .trailing)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
                ForEach(signals.map(RadarSignalItem.init)) { item in
                    Button { onSelect(item.signal) } label: {
                        RadarSignalRow(
                            signal: item.signal,
                            compact: compact,
                            isSelected: isSelected(item.signal)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected(item.signal) ? [.isSelected] : [])
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel()
    }

    private func isSelected(_ signal: ScanResult) -> Bool {
        signal.symbol == selected?.symbol &&
            signal.signalSource == selected?.signalSource &&
            signal.signalEpochMillis == selected?.signalEpochMillis
    }
}

private struct RadarSignalItem: Identifiable {
    let signal: ScanResult
    var id: String { "\(signal.symbol)|\(signal.signalSource)|\(signal.signalEpochMillis)" }
}
