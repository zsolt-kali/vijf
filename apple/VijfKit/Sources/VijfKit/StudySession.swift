/// One study session of a box, run in rounds (SPEC.md → Leitner rules).
///
/// `queue` is the rest of the current round and `total` its size, so the counter shows
/// `position / total`. "Not yet" cards collect in `retry` and become the next round when the
/// queue runs out. No answer ever changes the current round's total.
public struct StudySession: Equatable, Sendable {
    public let deckId: Int
    public let box: Int
    public private(set) var queue: [Int]
    public private(set) var retry: [Int] = []
    public private(set) var total: Int
    /// Answers given, for the summary: "Moved up to box n: up. Not yet: held."
    public private(set) var up = 0
    public private(set) var held = 0

    /// Starts a session with the box's cards in random order; nil when the box is empty.
    public init?(library: Library, deckId: Int, box: Int) {
        var g = SystemRandomNumberGenerator()
        self.init(library: library, deckId: deckId, box: box, using: &g)
    }

    public init?<G: RandomNumberGenerator>(library: Library, deckId: Int, box: Int, using g: inout G) {
        let ids = library.cards(inDeck: deckId, box: box).map(\.id).shuffled(using: &g)
        guard !ids.isEmpty else { return nil }
        self.deckId = deckId; self.box = box; self.queue = ids; self.total = ids.count
    }

    public var currentCardId: Int? { queue.first }
    public var isFinished: Bool { queue.isEmpty }
    /// 1-based position in the current round.
    public var position: Int { total - queue.count + 1 }
    /// Box 5 is review only: one Next button, no rating.
    public var isReviewOnly: Bool { box == 5 }

    /// Records an answer to the current card and moves on.
    public mutating func answer(known: Bool) {
        guard let id = queue.first else { return }
        if known { up += 1 } else { held += 1; retry.append(id) }
        advance()
    }

    /// Box 5's Next button.
    public mutating func next() { advance() }

    /// The current card was deleted: drop it from the round, keeping the position.
    public mutating func removeCurrent() {
        guard !queue.isEmpty else { return }
        total -= 1
        advance()
    }

    /// Undo of a delete: the card becomes the current one again.
    public mutating func reinsert(_ id: Int) {
        queue.insert(id, at: 0)
        total += 1
    }

    private mutating func advance() {
        queue.removeFirst()
        if queue.isEmpty && !retry.isEmpty {
            queue = retry
            retry = []
            total = queue.count
        }
    }
}
