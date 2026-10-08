import SwiftUI
import VijfKit

/// Studying one box in rounds (SPEC.md → Leitner rules, Screens → Study and Summary).
struct StudyView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let deckId: Int
    let box: Int
    @State private var flipped = false
    @State private var editing: Card?

    var body: some View {
        let session = model.study
        Group {
            if let session, let id = session.currentCardId, let card = model.library.card(id) {
                VStack(spacing: 18) {
                    FlashCard(card: card, flipped: flipped, reviewOnly: session.isReviewOnly) { editing = card }
                        .onTapGesture { withAnimation(reduceMotion ? nil : .spring(duration: 0.5)) { flipped.toggle() } }
                    if session.isReviewOnly {
                        Button("Next") { answer { model.next() } }.buttonStyle(.vj(.fill))
                    } else {
                        HStack(spacing: 8) {
                            Button("Not yet") { answer { model.answer(known: false) } }
                                .buttonStyle(.vj(.no, subtitle: "stays in box \(box)"))
                            Button("I know it") { answer { model.answer(known: true) } }
                                .buttonStyle(.vj(.yes, subtitle: "→ box \(box + 1)"))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 8)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(session.position) / \(session.total)")
                            .font(.vjMono(13)).monospacedDigit().foregroundStyle(VJ.ink)
                            .accessibilityLabel("Card \(session.position) of \(session.total)")
                    }
                }
            } else {
                Summary(box: box, up: session?.up ?? 0, held: session?.held ?? 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VJ.paper)
        .navigationTitle(model.library.deck(deckId)?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { card in EditCardView(card: card) }
    }

    private func answer(_ action: () -> Void) {
        action()
        flipped = false
    }
}

/// The two-sided card: your language on white, Dutch on yellow. The cog sits inside the card,
/// top-right, on both faces, and opens the editor without flipping the card.
private struct FlashCard: View {
    let card: Card
    let flipped: Bool
    let reviewOnly: Bool
    let edit: () -> Void

    var body: some View {
        ZStack {
            face(hint: "Your language", word: card.native, footer: "Tap to flip", back: false)
                .opacity(flipped ? 0 : 1)
            face(hint: "Dutch", word: card.dutch, footer: reviewOnly ? "Learned. Stays in box 5" : "Did you know it?", back: true)
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
        .frame(minHeight: 300, maxHeight: 420)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Flip") {}
    }

    private func face(hint: String, word: String, footer: String, back: Bool) -> some View {
        let fg = back ? VJ.onSignal : VJ.ink
        let soft = back ? VJ.onSignal : VJ.mute
        return VStack(alignment: .leading) {
            Eyebrow(hint, color: soft)
            Spacer()
            Text(word).font(.vjWord).tracking(-1.5).foregroundStyle(fg).fixedSize(horizontal: false, vertical: true)
            Spacer()
            Eyebrow(footer, color: soft)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(back ? VJ.signal : VJ.card)
        .overlay(Rectangle().strokeBorder(back ? VJ.onSignal : VJ.ink, lineWidth: VJ.stroke))
        .overlay(alignment: .topTrailing) {
            Button(action: edit) {
                Image(systemName: "gearshape").font(.system(size: 20, weight: .regular))
                    .frame(width: 44, height: 44)
            }
            .foregroundStyle(soft)
            .padding(8)
            .accessibilityLabel("Edit card")
        }
    }
}

private struct Summary: View {
    @Environment(AppModel.self) private var model
    let box: Int
    let up: Int
    let held: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Round complete.").font(.vjHeading)
            Text("Moved up to box \(min(box + 1, 5)): \(up). Not yet: \(held).").font(.vjNote).foregroundStyle(VJ.mute)
            HStack(spacing: 8) {
                Button("Back to boxes") { model.path.removeLast() }.buttonStyle(.vj(.fill))
                Button("Other deck") { model.path = [] }.buttonStyle(.vj())
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
