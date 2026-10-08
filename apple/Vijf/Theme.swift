import SwiftUI
import UIKit
import VijfKit

/// Colours from the vijf design system. Each follows the device's light or dark appearance.
enum VJ {
    static let paper = Color(Tokens.paper)
    static let card = Color(Tokens.card)
    static let ink = Color(Tokens.ink)
    static let onInk = Color(Tokens.onInk)
    static let onInkAccent = Color(Tokens.onInkAccent)
    static let mute = Color(Tokens.mute)
    static let line = Color(Tokens.line)
    static let signal = Color(Tokens.signal)
    static let onSignal = Color(Tokens.onSignal)
    static let deep = Color(Tokens.deep)
    static let success = Color(Tokens.success)
    static let onSuccess = Color(Tokens.onSuccess)
    static let danger = Color(Tokens.danger)
    static let onDanger = Color(Tokens.onDanger)

    /// The 1.5pt outline of cards, rows, buttons and inputs.
    static let stroke: CGFloat = 1.5
}

extension Color {
    init(_ pair: Tokens.Pair) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? pair.dark : pair.light)
        })
    }
}

extension UIColor {
    convenience init(hex: String) {
        let v = UInt32(hex.dropFirst(), radix: 16) ?? 0
        self.init(red: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255,
                  blue: CGFloat(v & 0xff) / 255, alpha: 1)
    }
}

extension Font {
    /// The design system's `sans` styles: SF Pro, heavy and tight for display.
    static let vjWordmark = Font.system(size: 34, weight: .heavy)
    static let vjWord = Font.system(size: 38, weight: .heavy)
    static let vjHeading = Font.system(size: 22, weight: .heavy)
    static let vjLabel = Font.system(size: 17, weight: .bold)
    static let vjButton = Font.system(size: 14, weight: .bold)
    static let vjBody = Font.system(size: 15)
    static let vjNote = Font.system(size: 13)

    /// The `mono` styles; uppercase ones get tracking where they are used.
    static func vjMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// Small uppercase mono text: field labels, card hints, the top bar.
struct Eyebrow: View {
    let text: String
    var color: Color = VJ.mute
    var size: CGFloat = 10

    init(_ text: String, color: Color = VJ.mute, size: CGFloat = 10) {
        self.text = text; self.color = color; self.size = size
    }

    var body: some View {
        Text(text.uppercased())
            .font(.vjMono(size))
            .tracking(size * 0.14)
            .foregroundStyle(color)
    }
}

/// The square, outlined button of the design system. `kind` sets the meaning.
struct VJButtonStyle: ButtonStyle {
    enum Kind { case outline, fill, no, yes, danger, ghost }
    var kind: Kind = .outline
    var subtitle: String? = nil

    func makeBody(configuration: Configuration) -> some View {
        let (bg, fg, border) = colors
        VStack(spacing: 3) {
            configuration.label.font(.vjButton)
            if let subtitle {
                Text(subtitle.uppercased()).font(.vjMono(9)).tracking(0.9)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 44)
        .foregroundStyle(fg)
        .background(bg)
        .overlay(Rectangle().strokeBorder(border, lineWidth: VJ.stroke))
        .opacity(configuration.isPressed ? 0.85 : 1)
        .contentShape(Rectangle())
    }

    private var colors: (Color, Color, Color) {
        switch kind {
        case .outline: (.clear, VJ.ink, VJ.ink)
        case .fill: (VJ.ink, VJ.onInk, VJ.ink)
        case .no: (VJ.danger, VJ.onDanger, VJ.danger)
        case .yes: (VJ.success, VJ.onSuccess, VJ.success)
        case .danger: (.clear, VJ.danger, VJ.danger)
        case .ghost: (.clear, VJ.mute, VJ.line)
        }
    }
}

extension ButtonStyle where Self == VJButtonStyle {
    static func vj(_ kind: VJButtonStyle.Kind = .outline, subtitle: String? = nil) -> VJButtonStyle {
        VJButtonStyle(kind: kind, subtitle: subtitle)
    }
}

/// A square input with the ink outline and a mono label above it.
struct VJField: View {
    let label: String
    @Binding var text: String
    var placeholder = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Eyebrow(label)
            TextField(placeholder, text: $text)
                .font(.system(size: 17))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(VJ.card)
                .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
        }
    }
}

/// The app's header: the wordmark with its blue dot, and a tally on the right.
struct Header: View {
    let tally: Text

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom) {
                (Text("vijf").foregroundStyle(VJ.ink) + Text(".").foregroundStyle(VJ.deep))
                    .font(.vjWordmark).tracking(-1.5)
                Spacer()
                tally.font(.vjMono(11)).foregroundStyle(VJ.mute).multilineTextAlignment(.trailing).lineSpacing(2).fixedSize()
            }
            Rectangle().fill(VJ.ink).frame(height: 2)
        }
    }
}
