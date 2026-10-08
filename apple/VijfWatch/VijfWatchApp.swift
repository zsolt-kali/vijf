import SwiftUI
import VijfKit

@main
struct VijfWatchApp: App {
    @State private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            WatchRoot()
                .environment(model)
        }
    }
}

enum WatchRoute: Hashable {
    case deck(Int)
    case study
}

/// Deck → boxes → study, as on the phone. With exactly one deck it opens straight into it.
struct WatchRoot: View {
    @Environment(WatchModel.self) private var model
    @State private var path: [WatchRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            DeckListView(path: $path)
                .navigationDestination(for: WatchRoute.self) { route in
                    switch route {
                    case .deck(let id): DeckBoxesView(deckId: id, path: $path)
                    case .study: WatchStudyView()
                    }
                }
        }
        .onAppear(perform: openOnlyDeck)
        .onChange(of: model.library.decks.map(\.id)) { openOnlyDeck() }
    }

    private func openOnlyDeck() {
        let decks = model.library.decks
        if path.isEmpty, decks.count == 1 { path = [.deck(decks[0].id)] }
        // A deck deleted on the phone: go back to the list.
        if case .deck(let id)? = path.first, model.library.deck(id) == nil { path = [] }
    }
}

/// Every deck, with its card count and how many are learned (box 5).
struct DeckListView: View {
    @Environment(WatchModel.self) private var model
    @Binding var path: [WatchRoute]

    var body: some View {
        let library = model.library
        Group {
            if library.decks.isEmpty {
                Text("Open vijf on your iPhone to send your decks to the watch.")
                    .font(.footnote).foregroundStyle(VJ.mute).multilineTextAlignment(.center).padding()
            } else {
                List(library.decks) { deck in
                    let total = library.cards(inDeck: deck.id).count
                    Button { path.append(.deck(deck.id)) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(deck.name).font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(total == 0 ? VJ.mute : VJ.ink)
                                Text(total == 1 ? "1 CARD" : "\(total) CARDS")
                                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(VJ.mute)
                            }
                            Spacer()
                            (Text("\(library.learnedCount(inDeck: deck.id))").foregroundColor(total == 0 ? VJ.mute : VJ.ink)
                             + Text("/\(total)").font(.system(size: 11, design: .monospaced)).foregroundColor(VJ.mute))
                                .font(.system(size: 17, weight: .bold, design: .monospaced))
                        }
                    }
                    .listRowBackground(VJ.card)
                    .accessibilityLabel("\(deck.name), \(total) cards, \(library.learnedCount(inDeck: deck.id)) learned")
                }
            }
        }
        .navigationTitle("Decks")
    }
}

/// One deck's five boxes. Empty boxes are greyed out and can't be opened.
struct DeckBoxesView: View {
    @Environment(WatchModel.self) private var model
    let deckId: Int
    @Binding var path: [WatchRoute]
    static let names = ["New", "Shaky", "Getting there", "Nearly", "Learned"]

    var body: some View {
        List(1...5, id: \.self) { box in
            let count = model.library.cards(inDeck: deckId, box: box).count
            Button {
                model.startStudy(deck: deckId, box: box)
                path.append(.study)
            } label: {
                HStack(spacing: 8) {
                    Text("\(box)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(width: 22, height: 22)
                        .foregroundStyle(count == 0 ? VJ.mute : (box == 5 ? VJ.onSignal : VJ.paper))
                        .background(count == 0 ? VJ.card : (box == 5 ? VJ.signal : VJ.ink))
                    Text(Self.names[box - 1]).font(.system(size: 15, weight: .bold))
                        .foregroundStyle(count == 0 ? VJ.mute : VJ.ink)
                    Spacer()
                    Text("\(count)").font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(count == 0 ? VJ.mute : VJ.ink)
                }
            }
            .disabled(count == 0)
            .listRowBackground(VJ.card)
            .accessibilityLabel("Box \(box), \(Self.names[box - 1]), \(count) cards")
        }
        .navigationTitle(model.library.deck(deckId)?.name ?? "")
    }
}
