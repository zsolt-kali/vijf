/// Going through a deck's cards without answering (SPEC.md → Browsing a deck).
///
/// Box 1 first, then in the order the cards were added. Nothing here changes a card: no box,
/// no `seenAt`. Previous and Next stop at the ends.
public struct BrowseSession: Equatable, Sendable {
    public let deckId: Int
    public private(set) var ids: [Int]
    public private(set) var index = 0

    /// Nil for a deck without cards.
    public init?(library: Library, deckId: Int) {
        let ids = library.browseOrder(inDeck: deckId).map(\.id)
        guard !ids.isEmpty else { return nil }
        self.deckId = deckId; self.ids = ids
    }

    public var currentCardId: Int? { ids.isEmpty ? nil : ids[index] }
    /// 1-based, for the counter "3 / 12".
    public var position: Int { index + 1 }
    public var total: Int { ids.count }
    public var isFirst: Bool { index == 0 }
    /// Next reads "Done" here.
    public var isLast: Bool { index >= ids.count - 1 }

    public mutating func next() { if !isLast { index += 1 } }
    public mutating func previous() { if !isFirst { index -= 1 } }

    /// The current card was deleted: the next one takes its place (the previous one if it was
    /// the last). Returns where it was, for undo.
    @discardableResult
    public mutating func removeCurrent() -> Int {
        let at = index
        ids.remove(at: at)
        index = min(index, max(ids.count - 1, 0))
        return at
    }

    /// Undo of a delete: the card goes back where it was and is shown again.
    public mutating func reinsert(_ id: Int, at: Int) {
        let at = min(at, ids.count)
        ids.insert(id, at: at)
        index = at
    }
}

extension Library {
    /// A deck's cards for browsing: box 1 first, then in the order they were added.
    public func browseOrder(inDeck deckId: Int) -> [Card] {
        cards(inDeck: deckId).sorted { ($0.box, $0.createdAt, $0.id) < ($1.box, $1.createdAt, $1.id) }
    }
}
