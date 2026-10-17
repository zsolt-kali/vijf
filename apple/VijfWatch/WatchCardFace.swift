import SwiftUI
import VijfKit

/// The card on the watch, for studying and browsing: your language on the front, Dutch on
/// yellow on the back. Long words shrink, then scroll, instead of ending in "…".
struct WatchCardFace: View {
    let card: Card
    let flipped: Bool
    /// "Did you know it?" when studying, "Tap to flip back" when browsing.
    let backFooter: String
    /// Shown at the right of the footer when browsing: "Box 3".
    var corner: String? = nil

    var body: some View {
        let back = flipped
        VStack(alignment: .leading) {
            Text((back ? "Dutch" : "Your language").uppercased())
                .font(.system(size: 9, design: .monospaced)).tracking(1.2)
            Spacer(minLength: 2)
            // The same sizes as before (26pt, shrinking to 60%); text that doesn't fit even
            // then scrolls (Digital Crown or swipe) instead of ending in "…".
            ViewThatFits(in: .vertical) {
                word(back ? card.dutch : card.native, size: 26)
                word(back ? card.dutch : card.native, size: 21)
                word(back ? card.dutch : card.native, size: 15.6)
                ScrollView {
                    word(back ? card.dutch : card.native, size: 15.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .id("\(card.id)-\(back)")   // a new card or a flip starts at the top
            }
            Spacer(minLength: 2)
            HStack {
                Text((back ? backFooter : "Tap to flip").uppercased())
                Spacer()
                if let corner { Text(corner.uppercased()) }
            }
            .font(.system(size: 9, design: .monospaced)).tracking(1.2)
        }
        .foregroundStyle(back ? VJ.onSignal : VJ.ink)
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(back ? VJ.signal : VJ.card, ignoresSafeAreaEdges: [])
        .contentShape(Rectangle())
    }

    private func word(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .heavy)).tracking(-size / 26)
            .fixedSize(horizontal: false, vertical: true)
    }
}
