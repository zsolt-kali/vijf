// SPEC.md → Data, Migration, Bulk import format. These protect existing users' progress.
import Foundation
import Testing
@testable import VijfKit

@Suite struct BackupTests {
    /// Saved data as the web app wrote it before decks existed.
    let v1 = """
    {"cards":[{"id":1,"native":"the house","dutch":"het huis","box":3,"createdAt":1,"reviewedAt":2},
              {"id":2,"native":"tomorrow","dutch":"morgen","box":5,"createdAt":1,"reviewedAt":2},
              {"id":5,"native":"busy","dutch":"druk","box":1,"createdAt":1,"reviewedAt":null}],"nextId":6}
    """

    @Test func preDeckDataMovesIntoStartKeepingEveryBox() throws {
        let l = try Backup.decode(v1)
        #expect(l.decks.map(\.name) == ["Start"])
        #expect(l.nextDeckId == 2)
        #expect(l.nextId == 6)
        #expect(l.cards.map { [$0.id, $0.box, $0.deckId] } == [[1, 3, 1], [2, 5, 1], [5, 1, 1]])
        #expect(l.cards[0].reviewedAt == 2 && l.cards[2].reviewedAt == nil)
    }

    @Test func aMissingNextIdIsRebuilt() throws {
        let l = try Backup.decode(#"{"cards":[{"id":7,"deckId":1,"native":"a","dutch":"a","box":1,"createdAt":1}],"decks":[{"id":1,"name":"Start","createdAt":1}]}"#)
        #expect(l.nextId == 8)
        #expect(l.nextDeckId == 2)
    }

    @Test func cardsWithoutAValidDeckJoinAnExistingStart() throws {
        let l = try Backup.decode(#"{"cards":[{"id":7,"deckId":99,"native":"lost","dutch":"kwijt","box":2,"createdAt":1}],"nextId":8,"decks":[{"id":1,"name":"Eten","createdAt":1},{"id":2,"name":"Start","createdAt":1}],"nextDeckId":3}"#)
        #expect(l.decks.map(\.name) == ["Eten", "Start"])
        #expect(l.card(7)?.deckId == 2)
        #expect(l.card(7)?.box == 2)
    }

    @Test func currentDataSurvivesARoundTripUnchanged() throws {
        var l = Library()
        let d = try l.makeDeck(named: "Eten", now: 1_700_000_000_000)
        l.addCard(native: "bread", dutch: "brood", to: d.id, now: 1_700_000_000_123)
        l.answer(1, known: true, now: 1_700_000_000_456)
        #expect(try Backup.decode(Backup.encode(l)) == l)
    }

    @Test func theBackupUsesTheWebAppsFieldNames() throws {
        var l = Library()
        let d = try l.makeDeck(named: "Start", now: 1)
        l.addCard(native: "a", dutch: "b", to: d.id, now: 2)
        let json = try #require(JSONSerialization.jsonObject(with: Backup.encode(l)) as? [String: Any])
        #expect(Set(json.keys) == ["cards", "nextId", "decks", "nextDeckId"])
        let card = try #require((json["cards"] as? [[String: Any]])?.first)
        #expect(Set(card.keys).isSuperset(of: ["id", "deckId", "native", "dutch", "box", "createdAt"]))
    }

    @Test func invalidTextIsRejected() {
        #expect(throws: Backup.Failure.invalid) { try Backup.decode("this is not json") }
        #expect(throws: Backup.Failure.invalid) { try Backup.decode(#"{"not": "a backup"}"#) }
    }
}

@Suite struct BulkImportTests {
    @Test func acceptsEverySeparatorAndSkipsOtherLines() {
        let text = ["bread = brood", "cheese|kaas", "milk\tmelk", "egg ; ei", "apple, appel",
                    "no separator here", "", "   ", "water = water = extra"].joined(separator: "\n")
        let pairs = BulkImport.pairs(from: text).map { "\($0.native)=\($0.dutch)" }
        #expect(pairs == ["bread=brood", "cheese=kaas", "milk=melk", "egg=ei", "apple=appel", "water=water"])
    }
}

@Suite struct TokensTests {
    /// The Swift colours must match design/tokens.json, like the web app's CSS.
    @Test func everyColourMatchesDesignTokens() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("design/tokens.json")
        let json = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let colors = try #require((json["color"] as? [String: Any])?["tokens"] as? [[String: Any]])
        var expected: [String: Tokens.Pair] = [:]
        for c in colors {
            let v = try #require(c["value"] as? [String: String])
            expected[c["name"] as! String] = Tokens.Pair(light: v["light"]!, dark: v["dark"]!)
        }
        #expect(Tokens.all == expected)
    }
}
