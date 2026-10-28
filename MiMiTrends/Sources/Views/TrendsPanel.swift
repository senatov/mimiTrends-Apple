import SwiftUI

enum TrendsColors {
    static var canvas: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }

    static var surface: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }
}

struct TrendsPanel: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(11)
            .background(TrendsColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.primary.opacity(contrast == .increased ? 0.28 : 0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.12 : 0.035), radius: 3, y: 1)
    }
}

extension View {
    func trendsPanel() -> some View {
        modifier(TrendsPanel())
    }
}
