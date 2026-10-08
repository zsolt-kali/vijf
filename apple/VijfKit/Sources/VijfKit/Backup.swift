import Foundation

/// Reading and writing the shared data format (SPEC.md → Data, Migration). The web app and the
/// native apps read each other's backups, so decoding is lenient in exactly the ways the web
/// app's `migrate()` is.
public enum Backup {
    public enum Failure: Error, Equatable { case invalid }

    /// Parses saved data or backup text from any version and brings it up to the current shape.
    public static func decode(_ data: Data) throws(Failure) -> Library {
        guard let raw = try? JSONSerialization.jsonObject(with: data),
              let object = raw as? [String: Any],
              let rawCards = object["cards"] as? [Any] else { throw .invalid }

        var cards: [Card] = []
        for case let c as [String: Any] in rawCards {
            guard let id = int(c["id"]) else { continue }
            cards.append(Card(
                id: id,
                deckId: int(c["deckId"]) ?? -1,
                native: c["native"] as? String ?? "",
                dutch: c["dutch"] as? String ?? "",
                box: min(max(int(c["box"]) ?? 1, 1), 5),
                createdAt: int64(c["createdAt"]) ?? 0,
                reviewedAt: int64(c["reviewedAt"])))
        }
        var decks: [Deck] = []
        for case let d as [String: Any] in object["decks"] as? [Any] ?? [] {
            guard let id = int(d["id"]) else { continue }
            decks.append(Deck(id: id, name: d["name"] as? String ?? "", createdAt: int64(d["createdAt"]) ?? 0))
        }
        var library = Library(cards: cards, nextId: int(object["nextId"]) ?? 0,
                              decks: decks, nextDeckId: int(object["nextDeckId"]) ?? 0)
        migrate(&library, now: .nowMillis)
        return library
    }

    public static func decode(_ text: String) throws(Failure) -> Library {
        try decode(Data(text.utf8))
    }

    /// The backup text: the same JSON the web app shows on its Backup screen.
    public static func encode(_ library: Library) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        // Encoding plain value types cannot fail.
        return (try? encoder.encode(library)) ?? Data("{}".utf8)
    }

    public static func text(_ library: Library) -> String {
        String(decoding: encode(library), as: UTF8.self)
    }

    /// Fills in missing counters and puts every card without a valid deck into a deck called
    /// Start (created if needed), keeping its box. Mirrors `migrate()` in web/index.html.
    static func migrate(_ l: inout Library, now: Int64) {
        if l.nextId <= 0 { l.nextId = (l.cards.map(\.id).max() ?? 0) + 1 }
        if l.nextDeckId <= 0 { l.nextDeckId = (l.decks.map(\.id).max() ?? 0) + 1 }
        let ids = Set(l.decks.map(\.id))
        if l.cards.contains(where: { !ids.contains($0.deckId) }) {
            let start = l.deck(named: "Start") ?? l.appendDeck(name: "Start", now: now)
            for i in l.cards.indices where !ids.contains(l.cards[i].deckId) {
                l.cards[i].deckId = start.id
            }
        }
    }

    /// A JSON number. `true`/`false` are rejected by type: `is Bool` would also match the
    /// numbers 0 and 1, which are valid ids.
    private static func number(_ v: Any?) -> NSNumber? {
        guard let n = v as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() else { return nil }
        return n
    }

    private static func int(_ v: Any?) -> Int? { number(v)?.intValue }
    private static func int64(_ v: Any?) -> Int64? { number(v)?.int64Value }
}
