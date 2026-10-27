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
                        Text("Move").frame(width: 74, alignment: .trailing)
                        Text("Price").frame(width: 70, alignment: .trailing)
                        Text("Saved").frame(width: 105, alignment: .trailing)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
                ForEach(signals.map(RadarSignalItem.init)) { item in
                    Button { onSelect(item.signal) } label: {
                        RadarSignalRow(signal: item.signal, compact: compact)
                    }
                    .buttonStyle(.plain)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected(item.signal) ? Color.accentColor.opacity(0.14) : Color.clear)
                    }
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

private struct RadarSignalRow: View {
    let signal: ScanResult
    let compact: Bool

    var body: some View {
        Group {
            if compact {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(signal.symbol).fontWeight(.semibold)
                        Spacer()
                        Text(signal.price.formatted()).monospacedDigit()
                    }
                    HStack {
                        Text(signal.signalSource.replacingOccurrences(of: "_", with: " "))
                            .lineLimit(1)
                        Spacer()
                        Text(signal.windowChangePercent, format: .number.precision(.fractionLength(2)))
                            .foregroundStyle(moveColor)
                        Text("%")
                            .foregroundStyle(moveColor)
                    }
                    .font(.caption)
                    Text(savedAt.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 8) {
                    Text(signal.symbol).fontWeight(.semibold).frame(width: 80, alignment: .leading)
                    Text(signal.signalSource.replacingOccurrences(of: "_", with: " "))
                        .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(signal.windowChangePercent.formatted(.number.precision(.fractionLength(2))))%")
                        .foregroundStyle(moveColor).frame(width: 74, alignment: .trailing)
                    Text(signal.price.formatted()).frame(width: 70, alignment: .trailing)
                    Text(savedAt, format: .dateTime.month().day().hour().minute())
                        .frame(width: 105, alignment: .trailing)
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var moveColor: Color { signal.windowChangePercent < 0 ? .red : .green }

    private var savedAt: Date {
        Date(timeIntervalSince1970: TimeInterval(signal.signalEpochMillis) / 1_000)
    }
}
