import SwiftUI
import VijfKit

/// Studying on the watch: the position counter on top, the card filling the screen (tap to
/// flip), and Not yet / I know it side by side. No editing: that happens on the phone.
struct WatchStudyView: View {
    @Environment(WatchModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var flipped = false

    var body: some View {
        if let session = model.study, let id = session.currentCardId, let card = model.library.card(id) {
            VStack(spacing: 6) {
                face(card: card, review: session.isReviewOnly)
                    .layoutPriority(1)
                    .onTapGesture { flipped.toggle() }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Flips the card")

                Group {
                    if session.isReviewOnly {
                        answerButton("Next", fill: VJ.ink, text: VJ.paper) { model.next() }
                    } else {
                        HStack(spacing: 6) {
                            answerButton("Not yet", fill: VJ.danger, text: VJ.onDanger) { model.answer(known: false) }
                            answerButton("I know it", fill: VJ.success, text: VJ.onSuccess) { model.answer(known: true) }
                        }
                    }
                }
                .frame(height: 44)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(session.position) / \(session.total)")
                        .font(.system(size: 13, design: .monospaced)).monospacedDigit()
                        .foregroundStyle(VJ.ink)
                        .accessibilityLabel("Card \(session.position) of \(session.total)")
                }
            }
        } else {
            VStack(spacing: 8) {
                Text("Round complete.").font(.system(size: 17, weight: .heavy))
                if let s = model.study {
                    Text("Moved up: \(s.up). Not yet: \(s.held).")
                        .font(.footnote).foregroundStyle(VJ.mute)
                }
                Button("Done") { dismiss() }
            }
        }
    }

    private func face(card: Card, review: Bool) -> some View {
        let back = flipped
        return VStack(alignment: .leading) {
            Text((back ? "Dutch" : "Your language").uppercased())
                .font(.system(size: 9, design: .monospaced)).tracking(1.2)
            Spacer(minLength: 2)
            Text(back ? card.dutch : card.native)
                .font(.system(size: 26, weight: .heavy)).tracking(-1)
                .minimumScaleFactor(0.6)
                .lineLimit(3)
            Spacer(minLength: 2)
            Text((back ? (review ? "Learned" : "Did you know it?") : "Tap to flip").uppercased())
                .font(.system(size: 9, design: .monospaced)).tracking(1.2)
        }
        .foregroundStyle(back ? VJ.onSignal : VJ.ink)
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(back ? VJ.signal : VJ.card, ignoresSafeAreaEdges: [])
        .contentShape(Rectangle())
    }

    private func answerButton(_ title: String, fill: Color, text: Color, action: @escaping () -> Void) -> some View {
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
    }
}
