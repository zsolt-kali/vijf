import SwiftUI
import VijfKit

/// The deck list (SPEC.md → Screens → Decks). Swipe a deck left to delete it.
struct DecksView: View {
    @Environment(AppModel.self) private var model
    @State private var newName = ""

    var body: some View {
        let decks = model.library.decks
        List {
            Header(tally: Text("\(decks.count)").font(.vjMono(15, weight: .bold)).foregroundColor(VJ.ink)
                   + Text("\n" + (decks.count == 1 ? "deck" : "decks")))
                .padding(.bottom, 12)
                .row()

            if decks.isEmpty {
                VStack(spacing: 8) {
                    Eyebrow("Empty")
                    Text("Make a deck for each topic, like food or work.").font(.vjBody)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(26)
                .overlay(Rectangle().strokeBorder(VJ.line, style: StrokeStyle(lineWidth: VJ.stroke, dash: [5, 4])))
                .row()
            }

            ForEach(decks) { deck in
                DeckRow(deck: deck)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) { model.deleteDeck(deck.id) }
                            .tint(VJ.danger)
                    }
                    .row()
            }

            HStack(spacing: 8) {
                TextField("New deck", text: $newName)
                    .font(.system(size: 17))
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .onSubmit(create)
                    .padding(12)
                    .background(VJ.card)
                    .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
                    .accessibilityLabel("New deck name")
                Button("Create", action: create).buttonStyle(.vj(.fill)).fixedSize()
            }
            .padding(.top, 14)
            .row()

            if model.library.cards.isEmpty {
                Button("Load 12 starter words") { model.addStarterSet() }.buttonStyle(.vj(.ghost)).row()
            }
            Button("Backup") { model.path.append(.backup) }.buttonStyle(.vj()).row()

            Text("Each deck has its own five boxes. The number on the right shows how many cards you have learned."
                 + (decks.isEmpty ? "" : " Swipe a deck left to delete it."))
                .font(.vjNote).foregroundStyle(VJ.mute).padding(.top, 10).row()
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(VJ.paper)
        .navigationTitle("Decks")
        .toolbar(.hidden, for: .navigationBar)
    }

    private func create() {
        if let error = model.makeDeck(named: newName) { model.show(error) } else { newName = "" }
    }
}

private struct DeckRow: View {
    @Environment(AppModel.self) private var model
    let deck: Deck

    var body: some View {
        let total = model.library.cards(inDeck: deck.id).count
        let learned = model.library.learnedCount(inDeck: deck.id)
        let empty = total == 0
        Button { model.path.append(.deck(deck.id)) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(deck.name).font(.vjLabel).foregroundStyle(empty ? VJ.mute : VJ.ink)
                    Eyebrow(total == 1 ? "1 card" : "\(total) cards")
                }
                Spacer()
                (Text("\(learned)").font(.vjMono(22, weight: .bold)).foregroundColor(empty ? VJ.mute : VJ.ink)
                 + Text("/\(total)").font(.vjMono(13)).foregroundColor(VJ.mute))
            }
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(VJ.card)
            .overlay(Rectangle().strokeBorder(empty ? VJ.line : VJ.ink, lineWidth: VJ.stroke))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(deck.name), \(total) cards, \(learned) learned")
    }
}

extension View {
    /// A List row without separators or inset backgrounds, 16pt side gutter.
    func row() -> some View {
        listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
