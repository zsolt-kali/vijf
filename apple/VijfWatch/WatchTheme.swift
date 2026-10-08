import SwiftUI
import VijfKit

/// Colours from the vijf design system. watchOS is always dark, so the watch uses each
/// token's dark value.
enum VJ {
    static let paper = Color(hex: Tokens.paper.dark)
    static let card = Color(hex: Tokens.card.dark)
    static let ink = Color(hex: Tokens.ink.dark)
    static let mute = Color(hex: Tokens.mute.dark)
    static let signal = Color(hex: Tokens.signal.dark)
    static let onSignal = Color(hex: Tokens.onSignal.dark)
    static let success = Color(hex: Tokens.success.dark)
    static let onSuccess = Color(hex: Tokens.onSuccess.dark)
    static let danger = Color(hex: Tokens.danger.dark)
    static let onDanger = Color(hex: Tokens.onDanger.dark)
}

extension Color {
    init(hex: String) {
        let v = UInt32(hex.dropFirst(), radix: 16) ?? 0
        self.init(red: Double((v >> 16) & 0xff) / 255, green: Double((v >> 8) & 0xff) / 255, blue: Double(v & 0xff) / 255)
    }
}
