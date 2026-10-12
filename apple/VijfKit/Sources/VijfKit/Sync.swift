import Foundation

/// Phone ⇄ watch sync rules (SPEC.md → Platforms → Apple Watch).
///
/// The phone is the source of truth for decks, words and deletions: it sends its whole library.
/// The watch only studies, so it sends back what changed there: each answer, with the card's box
/// after it. Because cards never move down, both sides keep the **higher** box, and both keep
/// the **later** `seenAt`, so studying on both devices before they sync loses nothing and a card
/// seen on either isn't due on the other the same day.
public enum Sync {
    /// One answer on the watch ("I know it" or "Not yet").
    public struct Review: Codable, Equatable, Sendable {
        public let cardId: Int
        /// The card's box after the answer.
        public let box: Int
        /// Milliseconds since 1970.
        public let at: Int64

        public init(cardId: Int, box: Int, at: Int64) {
            self.cardId = cardId; self.box = box; self.at = at
        }
    }

    // MARK: Phone side

    /// Applies the watch's answers. A card the phone has since deleted is skipped.
    public static func apply(_ reviews: [Review], to library: inout Library) {
        for r in reviews {
            guard let i = library.cards.firstIndex(where: { $0.id == r.cardId }) else { continue }
            library.cards[i].seenAt = max(library.cards[i].seenAt ?? .min, r.at)
            if r.box > library.cards[i].box {
                library.cards[i].box = min(r.box, 5)
                library.cards[i].reviewedAt = max(library.cards[i].reviewedAt ?? 0, r.at)
            }
        }
    }

    // MARK: Watch side

    /// The watch's copy after the phone's library arrives: decks, words and deletions come from
    /// the phone; a box the watch has moved further, or a later answer (one not yet applied on the
    /// phone), stays.
    public static func merge(phone: Library, into watch: Library) -> Library {
        var result = phone
        for i in result.cards.indices {
            guard let mine = watch.card(result.cards[i].id) else { continue }
            if mine.box > result.cards[i].box {
                result.cards[i].box = mine.box
                result.cards[i].reviewedAt = mine.reviewedAt
            }
            if (mine.seenAt ?? .min) > (result.cards[i].seenAt ?? .min) {
                result.cards[i].seenAt = mine.seenAt
            }
        }
        return result
    }

    /// Answers the phone's copy doesn't have yet (a higher box or a later `seenAt`), as reviews to
    /// send (again). Sent each time the phone's library arrives, so an answer that never reached
    /// the phone is not lost.
    public static func unsent(phone: Library, watch: Library, now: Int64) -> [Review] {
        phone.cards.compactMap { p in
            guard let w = watch.card(p.id),
                  w.box > p.box || (w.seenAt ?? .min) > (p.seenAt ?? .min) else { return nil }
            return Review(cardId: p.id, box: max(w.box, p.box), at: w.seenAt ?? w.reviewedAt ?? now)
        }
    }

    /// Records a watch answer as a review to send; nil if the card is gone.
    public static func review(afterAnswering cardId: Int, in library: Library, now: Int64) -> Review? {
        guard let card = library.card(cardId) else { return nil }
        return Review(cardId: cardId, box: card.box, at: now)
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
