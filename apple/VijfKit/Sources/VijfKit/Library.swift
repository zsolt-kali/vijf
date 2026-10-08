import Foundation

/// One flashcard. Field names match the web app's saved data and backup JSON.
public struct Card: Codable, Equatable, Identifiable, Sendable {
    public var id: Int
    public var deckId: Int
    public var native: String
    public var dutch: String
    /// Leitner box, 1–5. Cards only ever move up.
    public var box: Int
    /// Milliseconds since 1970, as in the web app.
    public var createdAt: Int64
    /// Set when the card last moved up; untouched by "Not yet".
    public var reviewedAt: Int64?

    public init(id: Int, deckId: Int, native: String, dutch: String, box: Int = 1,
                createdAt: Int64, reviewedAt: Int64? = nil) {
        self.id = id; self.deckId = deckId; self.native = native; self.dutch = dutch
        self.box = box; self.createdAt = createdAt; self.reviewedAt = reviewedAt
    }
}

public struct Deck: Codable, Equatable, Identifiable, Hashable, Sendable {
    public var id: Int
    public var name: String
    public var createdAt: Int64

    public init(id: Int, name: String, createdAt: Int64) {
        self.id = id; self.name = name; self.createdAt = createdAt
    }
}

/// Everything the user has: decks and cards. The same shape as the web app's
/// `localStorage` value and backup text (SPEC.md → Data).
public struct Library: Codable, Equatable, Sendable {
    public var cards: [Card]
    public var nextId: Int
    public var decks: [Deck]
    public var nextDeckId: Int

    public init(cards: [Card] = [], nextId: Int = 1, decks: [Deck] = [], nextDeckId: Int = 1) {
        self.cards = cards; self.nextId = nextId; self.decks = decks; self.nextDeckId = nextDeckId
    }

    public static let empty = Library()

    // MARK: Queries

    public func deck(_ id: Int) -> Deck? { decks.first { $0.id == id } }
    public func card(_ id: Int) -> Card? { cards.first { $0.id == id } }
    public func cards(inDeck deckId: Int) -> [Card] { cards.filter { $0.deckId == deckId } }
    public func cards(inDeck deckId: Int, box: Int) -> [Card] {
        cards.filter { $0.deckId == deckId && $0.box == box }
    }
    public func learnedCount(inDeck deckId: Int) -> Int { cards(inDeck: deckId, box: 5).count }

    /// Case-insensitive lookup by trimmed name, as the web app's `findDeck`.
    public func deck(named name: String) -> Deck? {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return decks.first { $0.name.lowercased() == key }
    }

    // MARK: Decks

    public enum DeckNameError: Error, Equatable { case empty, duplicate }

    /// Creates a deck. Names are trimmed, can't be empty, and must be unique ignoring case.
    @discardableResult
    public mutating func makeDeck(named raw: String, now: Int64) throws(DeckNameError) -> Deck {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { throw .empty }
        if deck(named: name) != nil { throw .duplicate }
        return appendDeck(name: name, now: now)
    }

    mutating func appendDeck(name: String, now: Int64) -> Deck {
        let d = Deck(id: nextDeckId, name: name, createdAt: now)
        nextDeckId += 1
        decks.append(d)
        return d
    }

    /// What a deck delete removed, so it can be undone.
    public struct DeletedDeck: Sendable, Equatable {
        public let deck: Deck
        public let index: Int
        public let cards: [Card]
    }

    /// Deletes a deck and all its cards.
    public mutating func deleteDeck(_ id: Int) -> DeletedDeck? {
        guard let index = decks.firstIndex(where: { $0.id == id }) else { return nil }
        let removed = DeletedDeck(deck: decks[index], index: index, cards: cards(inDeck: id))
        decks.remove(at: index)
        cards.removeAll { $0.deckId == id }
        return removed
    }

    /// Undo of `deleteDeck`: the deck goes back in its place with its cards and boxes.
    public mutating func restore(_ d: DeletedDeck) {
        decks.insert(d.deck, at: min(d.index, decks.count))
        cards.append(contentsOf: d.cards)
    }

    /// Loads the 12 starter words into a deck called Start (created if missing).
    @discardableResult
    public mutating func addStarterSet(now: Int64) -> Deck {
        let start = deck(named: "Start") ?? appendDeck(name: "Start", now: now)
        for (native, dutch) in Library.starterWords { addCard(native: native, dutch: dutch, to: start.id, now: now) }
        return start
    }

    public static let starterWords: [(String, String)] = [
        ("the house", "het huis"), ("the water", "het water"), ("the bread", "het brood"),
        ("tomorrow", "morgen"), ("always", "altijd"), ("together", "samen"),
        ("to work", "werken"), ("to understand", "begrijpen"), ("expensive", "duur"),
        ("busy", "druk"), ("nice / kind", "aardig"), ("almost", "bijna"),
    ]

    // MARK: Cards

    /// Adds a card to box 1. Both sides are required; returns nil when one is empty.
    @discardableResult
    public mutating func addCard(native: String, dutch: String, to deckId: Int, now: Int64) -> Card? {
        let n = native.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = dutch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty, !d.isEmpty else { return nil }
        let card = Card(id: nextId, deckId: deckId, native: n, dutch: d, box: 1, createdAt: now)
        nextId += 1
        cards.append(card)
        return card
    }

    /// Changes both meanings; box and review date stay. Returns false when a side is empty.
    @discardableResult
    public mutating func editCard(_ id: Int, native: String, dutch: String) -> Bool {
        let n = native.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = dutch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty, !d.isEmpty, let i = cards.firstIndex(where: { $0.id == id }) else { return false }
        cards[i].native = n
        cards[i].dutch = d
        return true
    }

    public struct DeletedCard: Sendable, Equatable {
        public let card: Card
        public let index: Int
    }

    public mutating func deleteCard(_ id: Int) -> DeletedCard? {
        guard let i = cards.firstIndex(where: { $0.id == id }) else { return nil }
        return DeletedCard(card: cards.remove(at: i), index: i)
    }

    public mutating func restore(_ d: DeletedCard) {
        cards.insert(d.card, at: min(d.index, cards.count))
    }

    /// An answer while studying. "I know it" moves the card up one box (at most 5) and
    /// records the time; "Not yet" changes nothing on the card.
    public mutating func answer(_ id: Int, known: Bool, now: Int64) {
        guard known, let i = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[i].box = min(cards[i].box + 1, 5)
        cards[i].reviewedAt = now
    }
}

public extension Int64 {
    /// Now, in the web app's unit (milliseconds since 1970).
    static var nowMillis: Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
}
