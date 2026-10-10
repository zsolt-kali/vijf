// SPEC.md → Search
import Testing
@testable import VijfKit

@Suite struct SearchTests {
    func sample() throws -> Library {
        var l = Library()
        let food = try l.makeDeck(named: "Food", now: 1)
        let work = try l.makeDeck(named: "Work", now: 1)
        let travel = try l.makeDeck(named: "Travel", now: 1)
        l.addCard(native: "the bread", dutch: "het brood", to: food.id, now: 1)
        l.addCard(native: "to break", dutch: "breken", to: work.id, now: 1)
        l.addCard(native: "wide", dutch: "breed", to: travel.id, now: 1)
        l.addCard(native: "coffee", dutch: "café", to: food.id, now: 1)
        l.addCard(native: "busy", dutch: "druk", to: work.id, now: 1)
        return l
    }

    @Test func findsCardsInEveryDeckInDeckOrder() throws {
        let l = try sample()
        let hits = Search.cards(matching: "bre", in: l)
        #expect(hits.map(\.card.native) == ["the bread", "to break", "wide"])
        #expect(hits.map(\.deck.name) == ["Food", "Work", "Travel"])
    }

    @Test func matchesEitherSideIgnoringCaseAndAccents() throws {
        let l = try sample()
        #expect(Search.cards(matching: "DRUK", in: l).map(\.card.native) == ["busy"])
        #expect(Search.cards(matching: "cafe", in: l).map(\.card.native) == ["coffee"])
        #expect(Search.cards(matching: "Café", in: l).map(\.card.native) == ["coffee"])
    }

    @Test func recordsWhereEachSideMatched() throws {
        let l = try sample()
        let hit = try #require(Search.cards(matching: "brood", in: l).first)
        #expect(hit.native == nil)
        let r = try #require(hit.dutch)
        #expect(hit.card.dutch[r] == "brood")

        let both = try #require(Search.cards(matching: "bre", in: l).first { $0.card.native == "to break" })
        #expect(both.native.map { both.card.native[$0] } == "bre")
        #expect(both.dutch.map { both.card.dutch[$0] } == "bre")
    }

    @Test func blankOrMissingFindsNothing() throws {
        let l = try sample()
        #expect(Search.cards(matching: "", in: l).isEmpty)
        #expect(Search.cards(matching: "   ", in: l).isEmpty)
        #expect(Search.cards(matching: "xyz", in: l).isEmpty)
    }
}
