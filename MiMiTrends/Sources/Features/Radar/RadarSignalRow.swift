import SwiftUI

struct RadarSignalRow: View {
    let signal: ScanResult
    let compact: Bool
    let isSelected: Bool

    var body: some View {
        Group {
            if compact {
                compactContent
            } else {
                wideContent
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(signal.symbol).fontWeight(.regular)
                Spacer()
                Text(signal.price.formatted()).monospacedDigit()
            }
            HStack(spacing: 8) {
                eventBadge
                Spacer(minLength: 4)
                movement
            }
            Text(savedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var wideContent: some View {
        HStack(spacing: 8) {
            Text(signal.symbol)
                .fontWeight(.regular)
                .frame(width: 80, alignment: .leading)
            eventBadge
                .frame(maxWidth: .infinity, alignment: .leading)
            movement
                .frame(width: 115, alignment: .trailing)
            Text(signal.price.formatted())
                .monospacedDigit()
                .frame(width: 70, alignment: .trailing)
            Text(savedAt, style: .relative)
                .lineLimit(1)
                .frame(width: 95, alignment: .trailing)
        }
        .font(.subheadline)
    }

    private var eventBadge: some View {
        Text(eventLabel)
            .font(.caption.weight(.regular))
            .foregroundStyle(eventColor)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(eventColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
    }

    private var movement: some View {
        Text("\(signal.windowChangePercent.formatted(.number.sign(strategy: .always()).precision(.fractionLength(2))))% / \(signal.signalWindowLabel)")
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(signal.windowChangePercent < 0 ? .red : .green)
            .lineLimit(1)
    }

    private var eventLabel: String {
        let label: String
        switch signal.signalSource.lowercased() {
        case "rapid crash": label = "‼ RAPID CRASH"
        case "rapid rise": label = "↑ RAPID RISE"
        case "sustained drop": label = "↓ SUSTAINED DROP"
        case "sustained rise": label = "↑ SUSTAINED RISE"
        case "tradable corridor": label = "▰ CORRIDOR"
        default: label = signal.signalSource.uppercased()
        }
        return signal.isRetained ? "\(label) · RECENT" : label
    }

    private var eventColor: Color {
        if signal.signalSource.lowercased() == "tradable corridor" { return .blue }
        return signal.windowChangePercent < 0 ? .red : .green
    }

    private var backgroundColor: Color {
        if signal.signalSource.lowercased() == "rapid crash" { return .yellow.opacity(0.20) }
        return isSelected ? Color.accentColor.opacity(0.10) : Color.primary.opacity(0.025)
    }

    private var savedAt: Date {
        Date(timeIntervalSince1970: TimeInterval(signal.signalEpochMillis) / 1_000)
    }
}
