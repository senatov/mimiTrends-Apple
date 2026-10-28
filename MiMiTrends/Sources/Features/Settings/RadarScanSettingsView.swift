import SwiftUI

struct RadarScanSettingsView: View {
    @Environment(RadarSession.self) private var radarSession
    @Environment(\.colorScheme) private var colorScheme
    @State private var draft = RadarScanPreferences()
    @State private var saved = RadarScanPreferences()
    @State private var message: String?
    @State private var didLoad = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Rapid moves").font(.title2.weight(.semibold))
                    Text("Thresholds for confirmed price changes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                section("Rapid crashes", accent: .red) {
                    doubleRow("Short drop", value: $draft.crashPercent, range: 0.05...20, step: 0.05, unit: "%")
                    intRow("Short window", value: $draft.crashWindowMinutes, range: 4...15, unit: "min")
                    doubleRow("Sustained drop", value: $draft.sustainedCrashPercent, range: 0.05...20, step: 0.05, unit: "%")
                    intRow("Long window", value: $draft.sustainedCrashWindowMinutes, range: 5...30, unit: "min")
                }
                section("Rapid rises", accent: .green) {
                    doubleRow("Minimum rise", value: $draft.risePercent, range: 0.05...20, step: 0.05, unit: "%")
                    intRow("Rise window", value: $draft.riseWindowMinutes, range: 1...15, unit: "min")
                }
                section("Liquid sustained moves", accent: .blue) {
                    doubleRow("Minimum move", value: $draft.sustainedMovePercent, range: 0.1...20, step: 0.1, unit: "%")
                    intRow("Move window", value: $draft.sustainedMoveWindowMinutes, range: 30...360, unit: "min")
                    amountRow("Window turnover", value: $draft.sustainedMoveMinimumTurnover)
                }
                section("Shared quality checks", accent: .teal) {
                    doubleRow("Minimum price", value: $draft.minimumPrice, range: 0...10_000, step: 0.5, unit: "")
                    amountRow("30-minute turnover", value: $draft.minimumTurnover)
                    Text("Turnover uses the instrument's source currency. Changes stop an active feed; start it again to scan with the saved thresholds.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        TrendsActionButton(title: "Save thresholds", systemImage: "checkmark") { save() }
                            .disabled(draft == saved)
                        TrendsActionButton(title: "Restore defaults", systemImage: "arrow.uturn.backward") {
                            draft = RadarScanPreferences()
                        }
                    }
                    if let message {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .background(TrendsColors.canvas(colorScheme))
        .navigationTitle(AppIdentity.windowTitle)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            saved = RadarScanPreferencesStore.load()
            draft = saved
        }
    }

    private func section<Content: View>(
        _ title: String, accent: Color, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel(accent: accent)
    }

    private func save() {
        do {
            try RadarScanPreferencesStore.save(draft)
            saved = draft.validated
            draft = saved
            radarSession.stop()
            message = "Thresholds saved on this device."
        } catch {
            message = "Could not save scanner thresholds."
        }
    }

    private func doubleRow(
        _ title: String, value: Binding<Double>, range: ClosedRange<Double>,
        step: Double, unit: String
    ) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue.formatted(.number.precision(.fractionLength(step < 1 ? 2 : 0)))) \(unit)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(title)
    }

    private func intRow(
        _ title: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String
    ) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue) \(unit)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(title)
    }

    private func amountRow(_ title: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 12)
            TextField(title, value: value, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 160)
                .accessibilityLabel(title)
        }
    }
}
