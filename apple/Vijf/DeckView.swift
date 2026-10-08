import SwiftUI
import VijfKit

/// One deck's five Leitner boxes (SPEC.md → Screens → Deck).
struct DeckView: View {
    @Environment(AppModel.self) private var model
    let deckId: Int
    @State private var adding = false

    static let boxNames = ["New", "Shaky", "Getting there", "Nearly", "Learned"]

    var body: some View {
        let library = model.library
        let total = library.cards(inDeck: deckId).count
        ScrollView {
            VStack(spacing: 8) {
                Header(tally: Text("\(library.learnedCount(inDeck: deckId))").font(.vjMono(15, weight: .bold)).foregroundColor(VJ.ink)
                       + Text(" / \(total)\nlearned"))
                    .padding(.bottom, 14)

                ForEach(1...5, id: \.self) { box in
                    BoxRow(box: box, name: Self.boxNames[box - 1], count: library.cards(inDeck: deckId, box: box).count) {
                        model.startStudy(deck: deckId, box: box)
                    }
                }

                if total == 0 {
                    VStack(spacing: 8) {
                        Eyebrow("Empty")
                        Text("Add your first word. It starts in box 1.").font(.vjBody)
                    }
                    .frame(maxWidth: .infinity).padding(26)
                    .overlay(Rectangle().strokeBorder(VJ.line, style: StrokeStyle(lineWidth: VJ.stroke, dash: [5, 4])))
                    .padding(.top, 14)
                }

                Button("Add words") { adding = true }.buttonStyle(.vj(.fill)).padding(.top, 14)

                Text("Tap a box to study it. **I know it** moves a card up one box; **Not yet** keeps it where it is. Cards never move down. Use the cog on a card to fix or delete it.")
                    .font(.vjNote).foregroundStyle(VJ.mute).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10)
            }
            .padding(.horizontal, 16).padding(.bottom, 40)
        }
        .background(VJ.paper)
        .navigationTitle(library.deck(deckId)?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $adding) { AddWordsView(deckId: deckId) }
    }
}

private struct BoxRow: View {
    let box: Int
    let name: String
    let count: Int
    let action: () -> Void

    var body: some View {
        let empty = count == 0
        let learned = box == 5 && !empty
        Button(action: action) {
            HStack(spacing: 12) {
                Text("\(box)")
                    .font(.vjMono(13, weight: .bold))
                    .frame(width: 40).frame(maxHeight: .infinity)
                    .foregroundStyle(learned ? VJ.onSignal : empty ? VJ.mute : VJ.onInk)
                    .background(learned ? VJ.signal : empty ? VJ.line : VJ.ink)
                VStack(alignment: .leading, spacing: 7) {
                    Text(name).font(.vjLabel).foregroundStyle(empty ? VJ.mute : VJ.ink)
                    if !empty {
                        HStack(spacing: 2) {
                            ForEach(0..<min(count, 20), id: \.self) { _ in
                                Rectangle().fill(VJ.deep).frame(width: 3, height: 12)
                            }
                        }
                    }
                }
                .padding(.vertical, 14)
                Spacer()
                Text("\(count)").font(.vjMono(22, weight: .bold)).foregroundStyle(empty ? VJ.mute : VJ.ink)
                    .padding(.trailing, 14)
            }
            .fixedSize(horizontal: false, vertical: true)
            .background(VJ.card)
            .overlay(Rectangle().strokeBorder(empty ? VJ.line : VJ.ink, lineWidth: VJ.stroke))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Box \(box), \(name), \(count) cards")
    }
}
