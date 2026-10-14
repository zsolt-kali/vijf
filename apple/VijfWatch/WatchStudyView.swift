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
                face(card: card)
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
        } else {
            VStack(spacing: 8) {
                Text("Round complete.").font(.system(size: 17, weight: .heavy))
                if let s = model.study {
                    Text(s.box == 5 ? "Stayed: \(s.up). Back to box 4: \(s.held)." : "Moved up: \(s.up). Not yet: \(s.held).")
                        .font(.footnote).foregroundStyle(VJ.mute)
                }
                Button("Done") { dismiss() }
            }
        }
    }

    private func face(card: Card) -> some View {
        let back = flipped
        return VStack(alignment: .leading) {
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
            Text((back ? "Did you know it?" : "Tap to flip").uppercased())
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
