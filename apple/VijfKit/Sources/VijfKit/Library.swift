import Foundation

/// One flashcard. Field names match the web app's saved data and backup JSON.
public struct Card: Codable, Equatable, Identifiable, Sendable {
    public var id: Int
    public var deckId: Int
    public var native: String
    public var dutch: String
    /// Leitner box, 1–5. "I know it" moves a card up one box, "Not yet" down one (or back to box 1,
    /// see `MissRule`).
    public var box: Int
    /// Milliseconds since 1970, as in the web app.
    public var createdAt: Int64
    /// Set on "I know it"; untouched by "Not yet".
    public var reviewedAt: Int64?
    /// Set on every answer, "I know it" or "Not yet"; the gap until the card is due again counts
    /// from its day. Missing (never answered, or data from before the daily rule): the card is due.
    public var seenAt: Int64?

    public init(id: Int, deckId: Int, native: String, dutch: String, box: Int = 1,
                createdAt: Int64, reviewedAt: Int64? = nil, seenAt: Int64? = nil) {
        self.id = id; self.deckId = deckId; self.native = native; self.dutch = dutch
        self.box = box; self.createdAt = createdAt; self.reviewedAt = reviewedAt; self.seenAt = seenAt
    }

    /// Days until a card answered "I know it" comes up again, for boxes 1–5.
    public static let gaps = [1, 2, 4, 8, 16]

    /// The start of the day this card is next due, or nil when it has never been answered (due
    /// now). After "I know it" (`reviewedAt` on the same day as `seenAt`; older versions set the
    /// two a moment apart) that is the box's gap; after "Not yet" it is the next day.
    public func dueDay(calendar: Calendar = .current) -> Int64? {
        guard let seenAt else { return nil }
        let seenDay = Day.start(of: Date(millis: seenAt), calendar: calendar)
        let known = (reviewedAt ?? .min) >= seenDay
        let days = known ? Card.gaps[min(max(box, 1), 5) - 1] : 1
        return Day.start(of: calendar.date(byAdding: .day, value: days, to: Date(millis: seenDay))!, calendar: calendar)
    }

    /// Whether a new study session shows this card on the day starting at `dayStart` (see `Day.start`).
    public func isDue(dayStart: Int64, calendar: Calendar = .current) -> Bool {
        (dueDay(calendar: calendar) ?? .min) <= dayStart
    }
}

extension Date {
    init(millis: Int64) { self.init(timeIntervalSince1970: TimeInterval(millis) / 1000) }
}

/// The rules count days (gaps, "left today") from local midnight.
public enum Day {
    /// The start of the day containing `date`, in milliseconds since 1970.
    public static func start(of date: Date = Date(), calendar: Calendar = .current) -> Int64 {
        Int64(calendar.startOfDay(for: date).timeIntervalSince1970 * 1000)
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
    /// The box's cards a new session shows today.
    public func dueCards(inDeck deckId: Int, box: Int, dayStart: Int64) -> [Card] {
        cards(inDeck: deckId, box: box).filter { $0.isDue(dayStart: dayStart) }
    }
    /// A deck's work for today: its cards due in any box.
    public func leftToday(inDeck deckId: Int, dayStart: Int64) -> Int {
        cards(inDeck: deckId).filter { $0.isDue(dayStart: dayStart) }.count
    }
    /// For a box with cards but none due: when the next one comes up, "Next tomorrow" or
    /// "Next in 3 days". Nil when the box is empty or has cards due.
    public func nextNote(inDeck deckId: Int, box: Int, dayStart: Int64, calendar: Calendar = .current) -> String? {
        let inBox = cards(inDeck: deckId, box: box)
        guard !inBox.isEmpty, !inBox.contains(where: { $0.isDue(dayStart: dayStart, calendar: calendar) }),
              let next = inBox.compactMap({ $0.dueDay(calendar: calendar) }).min() else { return nil }
        let days = calendar.dateComponents([.day], from: Date(millis: dayStart), to: Date(millis: next)).day ?? 1
        return days <= 1 ? "Next tomorrow" : "Next in \(days) days"
    }
    /// The deck row's second line: "8 left today", "Done for today", or "0 cards" for an empty deck.
    public func todayNote(inDeck deckId: Int, dayStart: Int64) -> String {
        if cards(inDeck: deckId).isEmpty { return "0 cards" }
        let left = leftToday(inDeck: deckId, dayStart: dayStart)
        return left == 0 ? "Done for today" : "\(left) left today"
    }

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

    /// An answer while studying. Both answers record the time as `seenAt`, so the card isn't
    /// due again until tomorrow; "I know it" also moves it up one box (at most 5) and records
    /// `reviewedAt`.
    public mutating func answer(_ id: Int, known: Bool, now: Int64, miss: MissRule = .oneDown) {
        guard let i = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[i].seenAt = now
        if known {
            cards[i].box = min(cards[i].box + 1, 5)
            cards[i].reviewedAt = now
        } else {
            cards[i].box = miss.boxAfterMiss(cards[i].box)
        }
    }
}

public extension Int64 {
    /// Now, in the web app's unit (milliseconds since 1970).
    static var nowMillis: Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
}
