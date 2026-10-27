import SwiftUI

struct TrendsPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

extension View {
    func trendsPanel() -> some View { modifier(TrendsPanel()) }
}
