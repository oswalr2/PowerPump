import SwiftUI
import UIKit

// MARK: - Colors (theme-adaptive)
extension Color {
    // Accent is the same in both themes
    static let sbAccent        = Color(hex: "#0A84FF")
    static let sbAccentDim     = Color(hex: "#0A84FF").opacity(0.15)
    static let sbRed           = Color(hex: "#FF4545")
    static let sbGreen         = Color(hex: "#34C759")

    // Adaptive: respond automatically to preferredColorScheme via UIColor trait collection
    static let sbBackground    = themed(dark: "#0A0A0A",  light: "#F2F2F7")
    static let sbSurface       = themed(dark: "#161616",  light: "#FFFFFF")
    static let sbSurfaceRaised = themed(dark: "#1E1E1E",  light: "#E8E8ED")
    static let sbTextPrimary   = themed(dark: "#FFFFFF",  light: "#0A0A0A")
    static let sbTextSecondary = themed(dark: "#888888",  light: "#6C6C72")
    static let sbBorder        = themed(dark: "#2A2A2A",  light: "#D1D1D6")

    // UIColor adaptive color — updates whenever preferredColorScheme changes
    private static func themed(dark: String, light: String) -> Color {
        Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Typography
struct SBFont {
    static func display(_ size: CGFloat = 34) -> Font { .system(size: size, weight: .black, design: .rounded) }
    static func heading(_ size: CGFloat = 22) -> Font  { .system(size: size, weight: .bold, design: .rounded) }
    static func body(_ size: CGFloat = 16) -> Font     { .system(size: size, weight: .regular, design: .rounded) }
    static func caption(_ size: CGFloat = 13) -> Font  { .system(size: size, weight: .medium, design: .rounded) }
    static func label(_ size: CGFloat = 11) -> Font    { .system(size: size, weight: .semibold, design: .rounded) }
}

// MARK: - Reusable Components

struct SBCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .background(Color.sbSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder, lineWidth: 1))
    }
}

struct SBPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isFullWidth: Bool = true

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SBFont.body())
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .padding(.horizontal, isFullWidth ? 0 : 32)
                .background(Color.sbAccent)
                .cornerRadius(14)
        }
    }
}

struct SBSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SBFont.body())
                .fontWeight(.semibold)
                .foregroundColor(.sbTextPrimary)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color.sbSurface)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder, lineWidth: 1))
        }
    }
}

struct SBTag: View {
    let text: String
    var color: Color = .sbAccent

    var body: some View {
        Text(LocalizedStringKey(text))
            .textCase(.uppercase)
            .font(SBFont.label())
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}

struct SBStatBox: View {
    let value: String
    let label: String
    var unit: String = ""
    var accent: Color = .sbAccent

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(SBFont.heading(28))
                    .foregroundColor(accent)
                Text(unit)
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
            }
            Text(LocalizedStringKey(label))
                .font(SBFont.label())
                .foregroundColor(.sbTextSecondary)
        }
    }
}

struct SBProgressBar: View {
    let progress: Double  // 0.0 – 1.0
    var color: Color = .sbAccent

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.sbBorder).frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geo.size.width * min(max(progress, 0), 1), height: 6)
                    .animation(.spring(), value: progress)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Slide-in animation modifier

extension View {
    func slideIn(_ trigger: Bool, delay: Double = 0) -> some View {
        self
            .opacity(trigger ? 1 : 0)
            .offset(y: trigger ? 0 : 18)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.82)
                .delay(delay),
                value: trigger
            )
    }
}
