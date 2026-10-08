// SPEC.md → Leitner rules: rounds and the position counter
import Testing
@testable import VijfKit

@Suite struct StudySessionTests {
    func library(_ count: Int, box: Int = 1) -> Library {
        Library(cards: (1...count).map { Card(id: $0, deckId: 1, native: "\($0)", dutch: "\($0)", box: box, createdAt: 0) },
                nextId: count + 1, decks: [Deck(id: 1, name: "Start", createdAt: 0)], nextDeckId: 2)
    }

    func counter(_ s: StudySession) -> String { "\(s.position) / \(s.total)" }

    @Test func anEmptyBoxHasNoSession() {
        #expect(StudySession(library: library(2, box: 1), deckId: 1, box: 3) == nil)
    }

    @Test func noAnswerEverChangesTheTotal() throws {
        var s = try #require(StudySession(library: library(3), deckId: 1, box: 1))
        #expect(counter(s) == "1 / 3")
        s.answer(known: true);  #expect(counter(s) == "2 / 3")
        s.answer(known: false); #expect(counter(s) == "3 / 3")
        s.answer(known: false)
        // round 2: the two Not yet cards
        #expect(counter(s) == "1 / 2")
        s.answer(known: true);  #expect(counter(s) == "2 / 2")
        s.answer(known: false)
        // round 3: the one card still not known
        #expect(counter(s) == "1 / 1")
        s.answer(known: true)
        #expect(s.isFinished)
        #expect(s.up == 3 && s.held == 3)
    }

    @Test func notYetCardsComeBackInAnswerOrder() throws {
        var s = try #require(StudySession(library: library(3), deckId: 1, box: 1))
        var first: [Int] = []
        for _ in 0..<3 { first.append(s.currentCardId!); s.answer(known: false) }
        var second: [Int] = []
        for _ in 0..<3 { second.append(s.currentCardId!); s.answer(known: true) }
        #expect(second == first)
    }

    @Test func onlyTheOpenDecksCardsAreStudied() throws {
        var l = library(2)
        l.cards.append(Card(id: 9, deckId: 2, native: "x", dutch: "x", box: 1, createdAt: 0))
        let s = try #require(StudySession(library: l, deckId: 1, box: 1))
        #expect(s.total == 2)
        #expect(!s.queue.contains(9))
    }

    @Test func box5IsReviewOnly() throws {
        var s = try #require(StudySession(library: library(1, box: 5), deckId: 1, box: 5))
        #expect(s.isReviewOnly)
        s.next()
        #expect(s.isFinished)
    }

    @Test func deletingTheCurrentCardKeepsThePositionAndUndoRestoresIt() throws {
        var s = try #require(StudySession(library: library(2), deckId: 1, box: 1))
        let first = s.currentCardId!
        s.removeCurrent()
        #expect(counter(s) == "1 / 1")
        s.reinsert(first)
        #expect(counter(s) == "1 / 2")
        #expect(s.currentCardId == first)
    }

    @Test func deletingTheLastCardOfARoundStartsTheNextRound() throws {
        var s = try #require(StudySession(library: library(2), deckId: 1, box: 1))
        let first = s.currentCardId!
        s.answer(known: false)
        #expect(counter(s) == "2 / 2")
        s.removeCurrent()
        #expect(counter(s) == "1 / 1")
        #expect(s.currentCardId == first)
    }
}
