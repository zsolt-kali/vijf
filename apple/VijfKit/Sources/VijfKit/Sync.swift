import Foundation

/// Phone ⇄ watch sync rules (SPEC.md → Platforms → Apple Watch).
///
/// The phone is the source of truth for decks, words and deletions: it sends its whole library.
/// The watch only studies, so it sends back what changed there: each answer, with the card's box
/// after it. For a card answered on both devices before they sync, the **latest answer wins**
/// (its box, `seenAt` and `reviewedAt`). Keeping the higher box would undo a box 5 card's move
/// back to box 4. Applying an answer twice, or an older one, changes nothing.
public enum Sync {
    /// One answer on the watch ("I know it" or "Not yet").
    public struct Review: Codable, Equatable, Sendable {
        public let cardId: Int
        /// The card's box after the answer.
        public let box: Int
        /// Milliseconds since 1970.
        public let at: Int64
        /// "I know it" (sets `reviewedAt`). Missing in reviews from an older watch app: taken as
        /// known when the box went up.
        public let known: Bool?

        public init(cardId: Int, box: Int, at: Int64, known: Bool) {
            self.cardId = cardId; self.box = box; self.at = at; self.known = known
        }
    }

    // MARK: Phone side

    /// Applies the watch's answers that are newer than the phone's last answer to the card. A
    /// card the phone has since deleted is skipped.
    public static func apply(_ reviews: [Review], to library: inout Library) {
        for r in reviews.sorted(by: { $0.at < $1.at }) {
            guard let i = library.cards.firstIndex(where: { $0.id == r.cardId }),
                  r.at > (library.cards[i].seenAt ?? .min) else { continue }
            let known = r.known ?? (r.box > library.cards[i].box)
            library.cards[i].box = min(max(r.box, 1), 5)
            library.cards[i].seenAt = r.at
            if known { library.cards[i].reviewedAt = r.at }
        }
    }

    // MARK: Watch side

    /// The watch's copy after the phone's library arrives: decks, words and deletions come from
    /// the phone; a card answered later on the watch (not yet applied on the phone) keeps the
    /// watch's box, `seenAt` and `reviewedAt`.
    public static func merge(phone: Library, into watch: Library) -> Library {
        var result = phone
        for i in result.cards.indices {
            guard let mine = watch.card(result.cards[i].id),
                  (mine.seenAt ?? .min) > (result.cards[i].seenAt ?? .min) else { continue }
            result.cards[i].box = mine.box
            result.cards[i].seenAt = mine.seenAt
            result.cards[i].reviewedAt = mine.reviewedAt
        }
        return result
    }

    /// Answers the phone's copy doesn't have yet (a later `seenAt` on the watch), as reviews to
    /// send (again). Sent each time the phone's library arrives, so an answer that never reached
    /// the phone is not lost.
    public static func unsent(phone: Library, watch: Library) -> [Review] {
        phone.cards.compactMap { p in
            guard let w = watch.card(p.id), let at = w.seenAt, at > (p.seenAt ?? .min) else { return nil }
            return Review(cardId: p.id, box: w.box, at: at, known: (w.reviewedAt ?? .min) >= at)
        }
    }

    /// Records a watch answer as a review to send; nil if the card is gone.
    public static func review(afterAnswering cardId: Int, known: Bool, in library: Library, now: Int64) -> Review? {
        guard let card = library.card(cardId) else { return nil }
        return Review(cardId: cardId, box: card.box, at: now, known: known)
    }

    // MARK: Payloads (WatchConnectivity dictionaries carry property-list values)

    static let libraryKey = "library"
    static let sentAtKey = "sentAt"
    static let reviewsKey = "reviews"

    /// The phone's library as an application context. The send time makes every context new, so
    /// the system delivers it even when the library hasn't changed since the last one.
    public static func context(for library: Library, sentAt: Int64) -> [String: Any] {
        [libraryKey: Backup.encode(library), sentAtKey: sentAt]
    }

    public static func library(fromContext context: [String: Any]) -> Library? {
        guard let data = context[libraryKey] as? Data else { return nil }
        return try? Backup.decode(data)
    }

    public static func userInfo(for reviews: [Review]) -> [String: Any] {
        [reviewsKey: (try? JSONEncoder().encode(reviews)) ?? Data()]
    }

    public static func reviews(fromUserInfo info: [String: Any]) -> [Review] {
        guard let data = info[reviewsKey] as? Data else { return [] }
        return (try? JSONDecoder().decode([Review].self, from: data)) ?? []
    }
}
