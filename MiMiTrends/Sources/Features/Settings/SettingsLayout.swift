import SwiftUI

enum SettingsColors {
    static var background: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }

    static var group: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }
}

struct SettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: (CGFloat) -> Content

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.title2.weight(.light))
                        Text(subtitle).font(.body.weight(.light))
                            .foregroundStyle(TrendsColors.supportingInk)
                    }
                    content(geometry.size.width)
                }
                .frame(maxWidth: 1600, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .foregroundStyle(TrendsColors.ink)
            }
        }
        .background(SettingsColors.background)
        .navigationTitle(title)
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title3.weight(.light))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(SettingsColors.group, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.primary.opacity(0.09), lineWidth: 1)
        }
    }
}

struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
            Spacer(minLength: 8)
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(TrendsColors.ink)
        }
        .font(.body.weight(.light))
    }
}
