import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appearance.theme.v1") private var theme = "light"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Appearance").font(.title2.weight(.semibold))
                    Text("Workspace colour and system typography")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 10) {
                    Label("Workspace", systemImage: "paintpalette")
                        .font(.headline)
                    Picker("Theme", selection: $theme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .trendsPanel(accent: .indigo)
                VStack(alignment: .leading, spacing: 9) {
                    Label("Typography and layout", systemImage: "textformat.size")
                        .font(.headline)
                    LabeledContent("Font", value: "System")
                    LabeledContent("Text size", value: "Follows device settings")
                    LabeledContent("Panels", value: "Resizable; positions saved")
                    Text("The native app follows Dynamic Type and system contrast. Desktop table colour and font overrides are not used in this SwiftUI layout.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .trendsPanel(accent: .cyan)
            }
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .background(TrendsColors.canvas(colorScheme))
        .navigationTitle(AppIdentity.windowTitle)
    }
}
