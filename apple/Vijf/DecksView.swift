import SwiftUI
import VijfKit

/// The deck list (SPEC.md → Screens → Decks, Search). Swipe a deck left to delete it; the "⋯"
/// menu holds New deck and Backup; typing in the search field swaps the decks for matching cards.
struct DecksView: View {
    @Environment(AppModel.self) private var model
    @State private var newName = ""
    @State private var naming = false
    @State private var query = ""
    @State private var editing: Card?

    var body: some View {
        let decks = model.library.decks
        let searching = !query.trimmingCharacters(in: .whitespaces).isEmpty
        List {
            Header { MoreMenu(newDeck: { naming = true }, backup: { model.path.append(.backup) }) }
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
            } else {
                SearchField(text: $query).padding(.bottom, 6).row()

                if searching {
                    let hits = Search.cards(matching: query, in: model.library)
                    HStack {
                        Eyebrow(hits.isEmpty ? "No cards match" : hits.count == 1 ? "1 card" : "\(hits.count) cards")
                        Spacer()
                    }
                    .row()
                    ForEach(hits) { hit in
                        HitRow(hit: hit) { editing = hit.card }.row()
                    }
                } else {
                    ForEach(decks) { deck in
                        DeckRow(deck: deck)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) { model.deleteDeck(deck.id) }
                                    .tint(VJ.danger)
                            }
                            .row()
                    }
                    Text("Each deck has its own five boxes. The number on the right shows how many cards you have learned. Swipe a deck left to delete it.")
                        .font(.vjNote).foregroundStyle(VJ.mute).padding(.top, 10).row()
                }
            }

            if model.library.cards.isEmpty {
                Button("Load 12 starter words") { model.addStarterSet() }.buttonStyle(.vj(.ghost)).padding(.top, 14).row()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .background(VJ.paper)
        .navigationTitle("Decks")
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editing) { card in EditCardView(card: card, fromSearch: true) }
        .alert("New deck", isPresented: $naming) {
            TextField("Name", text: $newName)
                .textInputAutocapitalization(.sentences)
            Button("Cancel", role: .cancel) { newName = "" }
            Button("Create", action: create)
        }
    }

    private func create() {
        if let error = model.makeDeck(named: newName) { model.show(error) } else { newName = ""; query = "" }
    }
}

/// The "⋯" button in the deck list's header, with the actions that used to sit below the decks.
private struct MoreMenu: View {
    let newDeck: () -> Void
    let backup: () -> Void

    var body: some View {
        Menu {
            Button("New deck", action: newDeck)
            Button("Backup", action: backup)
        } label: {
            Text("⋯")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(VJ.ink)
                .frame(width: 44, height: 44)
                .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More")
    }
}

/// The search field above the decks, with a clear button while it has text.
private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 0) {
            TextField("Search all cards", text: $text)
                .font(.system(size: 17))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .padding(12)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Text("×").font(.system(size: 22)).foregroundStyle(VJ.mute).frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .background(VJ.card)
        .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
    }
}

/// A card found by search: the native word, the Dutch word and its deck, and the box number.
/// The matched part is underlined in `deep`.
private struct HitRow: View {
    let hit: Search.Hit
    let open: () -> Void

    var body: some View {
        let card = hit.card
        let learned = card.box == 5
        Button(action: open) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    marked(card.native, hit.native).font(.vjLabel).foregroundColor(VJ.ink)
                    (marked(card.dutch, hit.dutch).foregroundColor(VJ.ink)
                     + Text(" · \(hit.deck.name)").foregroundColor(VJ.mute))
                        .font(.vjBody)
                }
                Spacer()
                Text("\(card.box)")
                    .font(.vjMono(13, weight: .bold))
                    .foregroundStyle(learned ? VJ.onSignal : VJ.onInk)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(learned ? VJ.signal : VJ.ink)
            }
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(VJ.card)
            .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(card.native), \(card.dutch), \(hit.deck.name), box \(card.box)")
    }

    private func marked(_ s: String, _ range: Range<String.Index>?) -> Text {
        var a = AttributedString(s)
        if let range, let r = Range(range, in: a) {
            a[r].underlineStyle = Text.LineStyle(pattern: .solid, color: VJ.deep)
        }
        return Text(a)
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
