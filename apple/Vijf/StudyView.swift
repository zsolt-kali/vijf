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
                    FlashCard(card: card, flipped: flipped,
                              edit: { editing = card }, speak: { DutchVoice.shared.say(card.dutch) })
                        .onTapGesture { withAnimation(reduceMotion ? nil : .spring(duration: 0.5)) { flipped.toggle() } }
                    HStack(spacing: 8) {
                        Button("Not yet") { answer { model.answer(known: false) } }
                            .buttonStyle(.vj(.no, subtitle: box > 1 ? "back to box \(box - 1)" : "stays in box 1"))
                        Button("I know it") { answer { model.answer(known: true) } }
                            .buttonStyle(.vj(.yes, subtitle: box == 5 ? "stays in box 5" : "→ box \(box + 1)"))
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
            } else if let session, session.isBetweenRounds {
                RoundBreak(round: session.round, notYet: session.retry.count)
            } else {
                Summary(line: session?.summary ?? "")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VJ.paper)
        .navigationTitle(model.library.deck(deckId)?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { card in EditCardView(card: card, origin: .study) }
        .onDisappear { DutchVoice.shared.stop() }
    }

    private func answer(_ action: () -> Void) {
        DutchVoice.shared.stop()
        action()
        flipped = false
    }
}

/// The two-sided card (also used when browsing): your language on white, Dutch on yellow. The cog sits inside the card,
/// top-right, on both faces, and opens the editor without flipping the card. On the Dutch side
/// a speaker beside it reads the word aloud.
struct FlashCard: View {
    let card: Card
    let flipped: Bool
    /// The back's footer: "Did you know it?" when studying, "Tap to flip back" when browsing.
    var backFooter = "Did you know it?"
    /// Shown at the right of both footers when browsing: "Box 3".
    var corner: String? = nil
    let edit: () -> Void
    let speak: () -> Void

    var body: some View {
        ZStack {
            face(hint: "Your language", word: card.native, footer: "Tap to flip", back: false)
                .opacity(flipped ? 0 : 1)
            face(hint: "Dutch", word: card.dutch, footer: backFooter, back: true)
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
            HStack {
                Eyebrow(footer, color: soft)
                Spacer()
                if let corner { Eyebrow(corner, color: soft) }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(back ? VJ.signal : VJ.card)
        .overlay(Rectangle().strokeBorder(back ? VJ.onSignal : VJ.ink, lineWidth: VJ.stroke))
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 0) {
                if back {
                    Button(action: speak) {
                        Image(systemName: "speaker.wave.2").font(.system(size: 20, weight: .regular))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Say the Dutch word")
                }
                Button(action: edit) {
                    Image(systemName: "gearshape").font(.system(size: 20, weight: .regular))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Edit card")
            }
            .foregroundStyle(soft)
            .padding(8)
        }
    }
}

/// Between two box 1 rounds: the "Not yet" cards can go round again, or wait until tomorrow.
private struct RoundBreak: View {
    @Environment(AppModel.self) private var model
    let round: Int
    let notYet: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Round \(round) done.").font(.vjHeading)
            Text("\(notYet) not yet.").font(.vjNote).foregroundStyle(VJ.mute)
            HStack(spacing: 8) {
                Button("Go again") { model.nextRound() }.buttonStyle(.vj(.fill))
                Button("Stop for today") { model.path.removeLast() }.buttonStyle(.vj())
            }
            Spacer()
        }
        .padding(16)
    }
}

private struct Summary: View {
    @Environment(AppModel.self) private var model
    /// "Moved up to box 2: 3. Not yet: 1."
    let line: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Round complete.").font(.vjHeading)
            Text(line).font(.vjNote).foregroundStyle(VJ.mute)
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
