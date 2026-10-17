/// One study session of a box, run in rounds (SPEC.md → Leitner rules).
///
/// `queue` is the rest of the current round and `total` its size, so the counter shows
/// `position / total`. "Not yet" cards collect in `retry`. When the queue runs out with cards in
/// `retry`, the session waits between rounds (`isBetweenRounds`) until `nextRound()` makes them
/// the next round, or the user stops. No answer ever changes the current round's total.
public struct StudySession: Equatable, Sendable {
    public let deckId: Int
    public let box: Int
    public private(set) var queue: [Int]
    public private(set) var retry: [Int] = []
    public private(set) var total: Int
    /// 1 for the first round, counting up with each `nextRound()`.
    public private(set) var round = 1
    /// Answers given, for the summary (see `summary`).
    public private(set) var up = 0
    public private(set) var held = 0
    /// Where "Not yet" sends a card above box 1, for the subtitle and the summary.
    public let miss: MissRule

    /// Starts a session with the box's cards due today (see `Card.isDue`) in random order; nil
    /// when there are none.
    public init?(library: Library, deckId: Int, box: Int, dayStart: Int64 = Day.start(), miss: MissRule = .oneDown) {
        var g = SystemRandomNumberGenerator()
        self.init(library: library, deckId: deckId, box: box, dayStart: dayStart, miss: miss, using: &g)
    }

    public init?<G: RandomNumberGenerator>(library: Library, deckId: Int, box: Int, dayStart: Int64 = Day.start(),
                                           miss: MissRule = .oneDown, using g: inout G) {
        let ids = library.dueCards(inDeck: deckId, box: box, dayStart: dayStart).map(\.id).shuffled(using: &g)
        guard !ids.isEmpty else { return nil }
        self.deckId = deckId; self.box = box; self.queue = ids; self.total = ids.count; self.miss = miss
    }

    /// The "Not yet" button's subtitle: "stays in box 1", "back to box 2" or "back to box 1".
    public var notYetSubtitle: String {
        box == 1 ? "stays in box 1" : "back to box \(miss.boxAfterMiss(box))"
    }

    public var currentCardId: Int? { queue.first }
    /// Every card known (or deleted): the summary shows.
    public var isFinished: Bool { queue.isEmpty && retry.isEmpty }
    /// A round is over and some cards were answered "Not yet": the round-end screen shows
    /// ("Round 1 done. 11 not yet.") with Go again and Stop for today.
    public var isBetweenRounds: Bool { queue.isEmpty && !retry.isEmpty }
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
            + (box > 1 ? "Back to box \(miss.boxAfterMiss(box)): \(held)." : "Not yet: \(held).")
    }

    /// The current card was deleted: drop it from the round, keeping the position.
    public mutating func removeCurrent() {
        guard !queue.isEmpty else { return }
        total -= 1
        advance()
    }

    /// Go again: the "Not yet" cards become the next round, in the order they were answered.
    public mutating func nextRound() {
        guard isBetweenRounds else { return }
        queue = retry
        retry = []
        total = queue.count
        round += 1
    }

    /// Undo of a delete: the card becomes the current one again.
    public mutating func reinsert(_ id: Int) {
        queue.insert(id, at: 0)
        total += 1
    }

    private mutating func advance() {
        queue.removeFirst()
    }
}
