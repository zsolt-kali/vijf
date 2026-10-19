import SwiftUI
import VijfKit

/// Going through a deck's cards without answering (SPEC.md → Browsing a deck): a dark band says
/// so, the card shows its box, and Previous / Next (Done on the last card) move along.
struct BrowseView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let deckId: Int
    @State private var flipped = false
    @State private var editing: Card?

    var body: some View {
        Group {
            if let b = model.browse, b.deckId == deckId, let id = b.currentCardId, let card = model.library.card(id) {
                VStack(spacing: 0) {
                    HStack {
                        Eyebrow("Browsing", color: VJ.onInkAccent, size: 11)
                        Spacer()
                        Text("\(b.position) / \(b.total)").font(.vjMono(11)).monospacedDigit().foregroundStyle(VJ.onInk)
                            .accessibilityLabel("Card \(b.position) of \(b.total)")
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(VJ.ink)

                    VStack(spacing: 18) {
                        FlashCard(card: card, flipped: flipped, backFooter: "Tap to flip back", corner: "Box \(card.box)",
                                  edit: { editing = card })
                            .onTapGesture { withAnimation(reduceMotion ? nil : .spring(duration: 0.5)) { flipped.toggle() } }
                        HStack(spacing: 8) {
                            Button("← Previous") { move { model.browsePrevious() } }
                                .buttonStyle(.vj()).disabled(b.isFirst)
                            if b.isLast {
                                Button("Done") { model.path.removeLast() }.buttonStyle(.vj(.fill))
                            } else {
                                Button("Next →") { move { model.browseNext() } }.buttonStyle(.vj(.fill))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.top, 16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(VJ.paper)
        .navigationTitle(model.library.deck(deckId)?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { card in EditCardView(card: card, origin: .browse) }
    }

    private func move(_ action: () -> Void) {
        action()
        flipped = false
    }
}
