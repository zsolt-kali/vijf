import SwiftUI
import VijfKit

/// Going through a deck's cards without answering: the card (tap to flip, its box in the
/// corner) and Previous / Next below it, Done on the last card. No editing, as everywhere on
/// the watch.
struct WatchBrowseView: View {
    @Environment(WatchModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var flipped = false

    var body: some View {
        if let b = model.browse, let id = b.currentCardId, let card = model.library.card(id) {
            VStack(spacing: 6) {
                WatchCardFace(card: card, flipped: flipped, backFooter: "Tap to flip back", corner: "Box \(card.box)")
                    .layoutPriority(1)
                    .onTapGesture { flipped.toggle() }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Flips the card")
                HStack(spacing: 6) {
                    navButton("←", label: "Previous", fill: VJ.card, text: b.isFirst ? VJ.mute : VJ.ink) { model.browsePrevious() }
                        .disabled(b.isFirst)
                    if b.isLast {
                        navButton("Done", label: "Done", fill: VJ.ink, text: VJ.onInk) { dismiss() }
                    } else {
                        navButton("Next →", label: "Next", fill: VJ.ink, text: VJ.onInk) { model.browseNext() }
                    }
                }
                .frame(height: 44)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(b.position) / \(b.total)")
                        .font(.system(size: 13, design: .monospaced)).monospacedDigit()
                        .foregroundStyle(VJ.ink)
                        .accessibilityLabel("Card \(b.position) of \(b.total)")
                }
            }
        }
    }

    private func navButton(_ title: String, label: String, fill: Color, text: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
            flipped = false
        } label: {
            Text(title).font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(text)
                .background(fill, ignoresSafeAreaEdges: [])
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
