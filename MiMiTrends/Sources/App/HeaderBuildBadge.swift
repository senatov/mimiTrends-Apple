#if os(macOS)
import SwiftUI

struct HeaderBuildBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.body)
                .foregroundStyle(.blue)
            Text(AppIdentity.name)
                .font(.body.weight(.light))
            Text("v. \(AppIdentity.version)")
                .font(.subheadline.weight(.light).monospaced())
                .foregroundStyle(.indigo)
        }
        .padding(.horizontal, 12)
        .headerBadgeSurface()
        .help(AppIdentity.windowTitle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppIdentity.windowTitle)
    }
}
#endif
