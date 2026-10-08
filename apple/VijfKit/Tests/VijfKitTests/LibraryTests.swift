// SPEC.md → Decks, Leitner rules, Editing a card
import Testing
@testable import VijfKit

@Suite struct DeckTests {
    @Test func namesAreTrimmedAndMustBeUniqueIgnoringCase() throws {
        var l = Library()
        let eten = try l.makeDeck(named: "  Eten ", now: 1)
        #expect(eten.name == "Eten")
        #expect(throws: Library.DeckNameError.duplicate) { try l.makeDeck(named: "eten", now: 2) }
        #expect(throws: Library.DeckNameError.empty) { try l.makeDeck(named: "   ", now: 2) }
        #expect(l.decks.map(\.name) == ["Eten"])
    }

    @Test func deletingADeckRemovesItsCardsAndUndoPutsThemBackInPlace() throws {
        var l = Library()
        let a = try l.makeDeck(named: "Start", now: 1)
        let b = try l.makeDeck(named: "Eten", now: 1)
        let c = try l.makeDeck(named: "Werk", now: 1)
        l.addCard(native: "bread", dutch: "brood", to: b.id, now: 1)
        l.answer(l.cards[0].id, known: true, now: 5)
        l.addCard(native: "house", dutch: "huis", to: a.id, now: 1)

        let deleted = l.deleteDeck(b.id)
        let removed = try #require(deleted)
        #expect(l.decks.map(\.id) == [a.id, c.id])
        #expect(l.cards.map(\.dutch) == ["huis"])

        l.restore(removed)
        #expect(l.decks.map(\.name) == ["Start", "Eten", "Werk"])
        #expect(l.card(1)?.box == 2)
    }

    @Test func starterSetGoesIntoStartBox1() {
        var l = Library()
        let start = l.addStarterSet(now: 1)
        #expect(start.name == "Start")
        #expect(l.cards.count == 12)
        #expect(l.cards.allSatisfy { $0.box == 1 && $0.deckId == start.id })
    }
}

@Suite struct CardTests {
    @Test func bothSidesAreRequired() {
        var l = Library()
        #expect(l.addCard(native: "bread", dutch: "  ", to: 1, now: 1) == nil)
        #expect(l.cards.isEmpty)
    }

    @Test func knowingMovesUpOneBoxAndStopsAt5() {
        var l = Library(cards: [Card(id: 1, deckId: 1, native: "a", dutch: "a", box: 4, createdAt: 0)], nextId: 2)
        l.answer(1, known: true, now: 10)
        #expect(l.card(1)?.box == 5)
        #expect(l.card(1)?.reviewedAt == 10)
        l.answer(1, known: true, now: 20)
        #expect(l.card(1)?.box == 5)
    }

    @Test func notYetChangesNothing() {
        let card = Card(id: 1, deckId: 1, native: "a", dutch: "a", box: 3, createdAt: 0, reviewedAt: 7)
        var l = Library(cards: [card], nextId: 2)
        l.answer(1, known: false, now: 10)
        #expect(l.card(1) == card)
    }

    @Test func editingKeepsBoxAndReviewDate() {
        var l = Library(cards: [Card(id: 1, deckId: 1, native: "the hous", dutch: "het huis", box: 3, createdAt: 0, reviewedAt: 1234)], nextId: 2)
        let saved = l.editCard(1, native: " the house ", dutch: "de woning")
        #expect(saved)
        #expect(l.card(1) == Card(id: 1, deckId: 1, native: "the house", dutch: "de woning", box: 3, createdAt: 0, reviewedAt: 1234))
        let rejected = !l.editCard(1, native: "", dutch: "x")
        #expect(rejected)
    }

    @Test func deletingACardCanBeUndone() throws {
        var l = Library()
        l.addCard(native: "a", dutch: "a", to: 1, now: 1)
        l.addCard(native: "b", dutch: "b", to: 1, now: 1)
        let deleted = l.deleteCard(1)
        let gone = try #require(deleted)
        #expect(l.cards.map(\.id) == [2])
        l.restore(gone)
        #expect(l.cards.map(\.id) == [1, 2])
    }
}
