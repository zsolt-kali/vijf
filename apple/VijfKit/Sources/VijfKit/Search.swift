import Foundation

/// Finding cards in every deck (SPEC.md → Search). Matches either side anywhere in the word,
/// ignoring case and accents: "cafe" finds "café".
public enum Search {
    public struct Hit: Equatable, Sendable, Identifiable {
        public let card: Card
        public let deck: Deck
        /// Where the search text was found in each side, if it was.
        public let native: Range<String.Index>?
        public let dutch: Range<String.Index>?

        public var id: Int { card.id }
    }

    /// Where `query` occurs in `text`, ignoring case and accents. An empty query matches nothing.
    public static func range(of query: String, in text: String) -> Range<String.Index>? {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return nil }
        return text.range(of: q, options: [.caseInsensitive, .diacriticInsensitive])
    }

    /// The matching cards, in deck order and then in the order they were added.
    public static func cards(matching query: String, in library: Library) -> [Hit] {
        library.decks.flatMap { deck in
            library.cards(inDeck: deck.id).compactMap { card in
                let n = range(of: query, in: card.native)
                let d = range(of: query, in: card.dutch)
                return n == nil && d == nil ? nil : Hit(card: card, deck: deck, native: n, dutch: d)
            }
        }
    }
}
