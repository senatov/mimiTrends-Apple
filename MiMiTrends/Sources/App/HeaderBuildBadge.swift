#if os(macOS)
import SwiftUI

struct HeaderBuildBadge: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.blue)
            Text(AppIdentity.name)
                .font(.system(size: 12, weight: .semibold))
            Text(AppIdentity.version)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .headerBadgeSurface()
        .help(AppIdentity.windowTitle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppIdentity.windowTitle)
    }
}
#endif
