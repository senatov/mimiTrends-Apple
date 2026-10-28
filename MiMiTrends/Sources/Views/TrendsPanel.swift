import SwiftUI

enum TrendsColors {
    static func canvas(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.035, green: 0.075, blue: 0.125)
            : Color(red: 0.925, green: 0.960, blue: 0.990)
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.075, green: 0.130, blue: 0.205)
            : .white
    }

    static func border(_ scheme: ColorScheme, highContrast: Bool) -> Color {
        scheme == .dark
            ? Color(red: 0.25, green: 0.42, blue: 0.59).opacity(highContrast ? 1 : 0.72)
            : Color(red: 0.58, green: 0.72, blue: 0.85).opacity(highContrast ? 1 : 0.68)
    }
}

struct TrendsPanel: ViewModifier {
    let accent: Color

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(11)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(TrendsColors.surface(colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accent.opacity(colorScheme == .dark ? 0.09 : 0.055))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        TrendsColors.border(colorScheme, highContrast: contrast == .increased),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .top) {
                Capsule()
                    .fill(accent.opacity(contrast == .increased ? 1 : 0.85))
                    .frame(height: 3)
                    .padding(.horizontal, 14)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.18 : 0.05), radius: 4, y: 2)
    }
}

extension View {
    func trendsPanel(accent: Color = .blue) -> some View {
        modifier(TrendsPanel(accent: accent))
    }
}
