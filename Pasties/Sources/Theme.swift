import SwiftUI

/// Atlassian Design System tokens (light theme), used to give Pasties an
/// authentic Atlassian look. Values mirror the ADS color palette and type scale.
/// https://atlassian.design/foundations
enum ADS {
    // Brand / Blue
    static let brand        = Color(hex: 0x0C66E4) // Blue700 — primary action
    static let brandHover   = Color(hex: 0x0055CC) // Blue800
    static let brandPressed = Color(hex: 0x09326C) // Blue900
    static let brandSubtle  = Color(hex: 0xE9F2FF) // Blue100 — selected/subtle bg
    static let link         = Color(hex: 0x1868DB)

    // Neutrals (light)
    static let surface      = Color(hex: 0xFFFFFF)
    static let sunken       = Color(hex: 0xF7F8F9) // Neutral100
    static let subtleHover  = Color(hex: 0xF1F2F4) // Neutral200
    static let border       = Color(hex: 0xDCDFE4) // Neutral300

    // Text
    static let text         = Color(hex: 0x172B4D) // default text (navy)
    static let textSubtle   = Color(hex: 0x44546F)
    static let textSubtlest = Color(hex: 0x626F86)

    // Danger
    static let danger       = Color(hex: 0xC9372C) // Red600
    static let dangerHover  = Color(hex: 0xAE2A19) // Red700

    // Radius (ADS border.radius)
    static let radius: CGFloat     = 3  // border.radius.100
    static let radiusCard: CGFloat = 8  // border.radius.300
}

extension Color {
    /// Create a Color from a 0xRRGGBB integer.
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8)  & 0xFF) / 255,
                  blue:  Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

extension Font {
    // ADS type scale (system font = the same stack Atlassian product UI uses).
    static let adsHeading    = Font.system(size: 16, weight: .semibold)
    static let adsBody       = Font.system(size: 14)
    static let adsBodyMedium = Font.system(size: 14, weight: .medium)
    static let adsSmall      = Font.system(size: 12)
    static let adsSmallBold  = Font.system(size: 11, weight: .semibold)
}

// MARK: - Atlassian-style buttons

/// Primary (bold brand) button — solid blue, white text.
struct ADSPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.adsBodyMedium)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? ADS.brandHover : ADS.brand,
                        in: RoundedRectangle(cornerRadius: ADS.radius))
            .contentShape(Rectangle())
    }
}

/// Subtle (default) button — transparent until hover/press.
struct ADSSubtleButton: ButtonStyle {
    var role: ButtonRole?
    func makeBody(configuration: Configuration) -> some View {
        let fg = role == .destructive ? ADS.danger : ADS.textSubtle
        return configuration.label
            .font(.adsBodyMedium)
            .foregroundStyle(fg)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? ADS.subtleHover : Color.clear,
                        in: RoundedRectangle(cornerRadius: ADS.radius))
            .contentShape(Rectangle())
    }
}

/// A small keyboard-key lozenge, e.g. ⌘ or ⇧V.
struct Keycap: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(ADS.textSubtle)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(ADS.sunken, in: RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(ADS.border, lineWidth: 1))
    }
}
