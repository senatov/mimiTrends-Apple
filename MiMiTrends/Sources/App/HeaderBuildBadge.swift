#if os(macOS)
import SwiftUI

struct HeaderBuildBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.blue)
            Text(AppIdentity.name)
                .font(.system(size: 14, weight: .regular))
            Text("v. \(AppIdentity.version)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
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
