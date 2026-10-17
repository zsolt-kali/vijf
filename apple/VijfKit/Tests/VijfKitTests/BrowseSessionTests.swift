// SPEC.md → Browsing a deck
import Testing
@testable import VijfKit

@Suite struct BrowseSessionTests {
    func library() -> Library {
        Library(cards: [
            Card(id: 1, deckId: 1, native: "a", dutch: "a", box: 3, createdAt: 10),
            Card(id: 2, deckId: 1, native: "b", dutch: "b", box: 1, createdAt: 30),
            Card(id: 3, deckId: 1, native: "c", dutch: "c", box: 1, createdAt: 20),
            Card(id: 4, deckId: 1, native: "d", dutch: "d", box: 5, createdAt: 5),
            Card(id: 9, deckId: 2, native: "x", dutch: "x", box: 1, createdAt: 1),
        ], nextId: 10, decks: [Deck(id: 1, name: "Start", createdAt: 0), Deck(id: 2, name: "Eten", createdAt: 0)], nextDeckId: 3)
    }

    @Test func boxOneFirstThenInTheOrderAdded() throws {
        let b = try #require(BrowseSession(library: library(), deckId: 1))
        #expect(b.ids == [3, 2, 1, 4])
        #expect(b.currentCardId == 3 && b.position == 1 && b.total == 4)
    }

    @Test func previousAndNextStopAtTheEnds() throws {
        var b = try #require(BrowseSession(library: library(), deckId: 1))
        #expect(b.isFirst)
        b.previous()
        #expect(b.position == 1)
        b.next(); b.next(); b.next()
        #expect(b.isLast && b.currentCardId == 4)
        b.next()
        #expect(b.position == 4)
        b.previous()
        #expect(b.currentCardId == 1)
    }

    @Test func browsingChangesNoCard() throws {
        let l = library()
        var b = try #require(BrowseSession(library: l, deckId: 1))
        b.next(); b.next()
        #expect(l == library())
    }

    @Test func aDeckWithoutCardsCannotBeBrowsed() {
        var l = library()
        l.cards.removeAll { $0.deckId == 2 }
        #expect(BrowseSession(library: l, deckId: 2) == nil)
    }

    @Test func deletingTheShownCardShowsTheNextAndUndoBringsItBack() throws {
        var b = try #require(BrowseSession(library: library(), deckId: 1))
        b.next()                                  // card 2
        let at = b.removeCurrent()
        #expect(at == 1 && b.currentCardId == 1 && b.total == 3)
        b.reinsert(2, at: at)
        #expect(b.currentCardId == 2 && b.total == 4)
        b.next(); b.next()                        // the last card, 4
        b.removeCurrent()
        #expect(b.currentCardId == 1 && b.isLast)
    }
}
