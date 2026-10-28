#if os(macOS)
import SwiftUI

struct HeaderBadgeSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 38)
            .background {
                Capsule()
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay {
                        Capsule()
                            .strokeBorder(.primary.opacity(0.15), lineWidth: 0.75)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 1.5, y: 1)
            }
    }
}

extension View {
    func headerBadgeSurface() -> some View {
        modifier(HeaderBadgeSurface())
    }
}
#endif
