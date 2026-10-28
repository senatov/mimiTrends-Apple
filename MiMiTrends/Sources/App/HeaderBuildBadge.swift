#if os(macOS)
import SwiftUI

struct HeaderBuildBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.blue)
            Text(AppIdentity.name)
                .font(.system(size: 11, weight: .semibold))
            Text(AppIdentity.version)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .frame(height: 30)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(.primary.opacity(0.14), lineWidth: 0.7)
        }
        .help(AppIdentity.windowTitle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppIdentity.windowTitle)
    }
}
#endif
