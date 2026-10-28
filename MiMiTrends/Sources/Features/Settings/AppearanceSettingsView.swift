import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("appearance.theme.v1") private var theme = "light"

    var body: some View {
        SettingsPage(title: "Appearance", subtitle: "Workspace colour and system typography") { width in
            if width >= 900 {
                HStack(alignment: .top, spacing: 18) {
                    workspaceGroup
                    typographyGroup
                }
            } else {
                workspaceGroup
                typographyGroup
            }
        }
    }

    private var workspaceGroup: some View {
        SettingsGroup(title: "Workspace") {
            Picker("Theme", selection: $theme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
    }

    private var typographyGroup: some View {
        SettingsGroup(title: "Typography and layout") {
            LabeledContent("Font", value: "System")
            LabeledContent("Text size", value: "Follows device settings")
            LabeledContent("Panels", value: "Resizable; positions saved")
            Text("The native app follows Dynamic Type and system contrast. Desktop table colour and font overrides are not used in this SwiftUI layout.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
