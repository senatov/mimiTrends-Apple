import SwiftUI

struct WatchlistEntryRow: View {
    let entry: WatchlistEntry
    let isWorking: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 10) {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.symbol).font(.headline)
                        Text("Added \(addedAt.formatted(.dateTime.month().day().year()))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Show this symbol on Radar")
            Button(role: .destructive, action: onRemove) {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .buttonStyle(TrendsActionButtonStyle(tint: .red, compact: true))
            .disabled(isWorking)
            .accessibilityLabel("Remove \(entry.symbol)")
        }
        .padding(.vertical, 4)
    }

    private var addedAt: Date {
        Date(timeIntervalSince1970: TimeInterval(entry.addedAtMillis) / 1_000)
    }
}
