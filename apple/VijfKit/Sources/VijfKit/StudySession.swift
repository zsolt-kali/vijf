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
    /// Answers given, for the summary (see `summary`).
    public private(set) var up = 0
    public private(set) var held = 0

    /// Starts a session with the box's cards due today (see `Card.isDue`) in random order; nil
    /// when there are none.
    public init?(library: Library, deckId: Int, box: Int, dayStart: Int64 = Day.start()) {
        var g = SystemRandomNumberGenerator()
        self.init(library: library, deckId: deckId, box: box, dayStart: dayStart, using: &g)
    }

    public init?<G: RandomNumberGenerator>(library: Library, deckId: Int, box: Int, dayStart: Int64 = Day.start(), using g: inout G) {
        let ids = library.dueCards(inDeck: deckId, box: box, dayStart: dayStart).map(\.id).shuffled(using: &g)
        guard !ids.isEmpty else { return nil }
        self.deckId = deckId; self.box = box; self.queue = ids; self.total = ids.count
    }

    public var currentCardId: Int? { queue.first }
    public var isFinished: Bool { queue.isEmpty }
    /// 1-based position in the current round.
    public var position: Int { total - queue.count + 1 }
    /// Records an answer to the current card and moves on. In box 1 "Not yet" brings the card
    /// back in the next round; in boxes 2–5 the card has gone down a box and leaves the session
    /// (another round would only move it straight back up).
    public mutating func answer(known: Bool) {
        guard let id = queue.first else { return }
        if known { up += 1 } else { held += 1; if box == 1 { retry.append(id) } }
        advance()
    }

    /// The summary line shown when the session is over: "Moved up to box 3: 4. Back to box 1: 2."
    public var summary: String {
        (box == 5 ? "Stayed in box 5: \(up). " : "Moved up to box \(box + 1): \(up). ")
            + (box > 1 ? "Back to box \(box - 1): \(held)." : "Not yet: \(held).")
    }

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
