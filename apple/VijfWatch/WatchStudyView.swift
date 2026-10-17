import SwiftUI
import VijfKit

/// Studying on the watch: the position counter on top, the card filling the screen (tap to
/// flip), and Not yet / I know it side by side; between box 1 rounds, Go again / Stop for today.
/// No editing: that happens on the phone.
struct WatchStudyView: View {
    @Environment(WatchModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var flipped = false

    var body: some View {
        if let session = model.study, let id = session.currentCardId, let card = model.library.card(id) {
            VStack(spacing: 6) {
                WatchCardFace(card: card, flipped: flipped, backFooter: "Did you know it?")
                    .layoutPriority(1)
                    .onTapGesture { flipped.toggle() }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Flips the card")

                HStack(spacing: 6) {
                    answerButton("Not yet", fill: VJ.danger, text: VJ.onDanger) { model.answer(known: false) }
                    answerButton("I know it", fill: VJ.success, text: VJ.onSuccess) { model.answer(known: true) }
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
        } else if let session = model.study, session.isBetweenRounds {
            VStack(spacing: 8) {
                Text("Round \(session.round) done.").font(.system(size: 17, weight: .heavy))
                Text("\(session.retry.count) not yet.").font(.footnote).foregroundStyle(VJ.mute)
                Button("Go again") { model.nextRound() }
                Button("Stop for today") { dismiss() }
            }
        } else {
            VStack(spacing: 8) {
                Text("Round complete.").font(.system(size: 17, weight: .heavy))
                if let s = model.study {
                    Text(s.summary)
                        .font(.footnote).foregroundStyle(VJ.mute)
                }
                Button("Done") { dismiss() }
            }
        }
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
