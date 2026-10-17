// SPEC.md → Leitner rules: the "Not yet" setting
import Testing
@testable import VijfKit

@Suite struct MissRuleTests {
    @Test func oneDownOrBackToBoxOne() {
        #expect((1...5).map(MissRule.oneDown.boxAfterMiss) == [1, 1, 2, 3, 4])
        #expect((1...5).map(MissRule.backToBoxOne.boxAfterMiss) == [1, 1, 1, 1, 1])
    }

    @Test func notYetFollowsTheSetting() {
        var l = Library(cards: [Card(id: 1, deckId: 1, native: "a", dutch: "a", box: 4, createdAt: 0, reviewedAt: 7)], nextId: 2)
        l.answer(1, known: false, now: 10, miss: .backToBoxOne)
        #expect(l.card(1)?.box == 1)
        #expect(l.card(1)?.seenAt == 10 && l.card(1)?.reviewedAt == 7)
        l.cards[0].box = 4
        l.answer(1, known: false, now: 20)
        #expect(l.card(1)?.box == 3)
    }

    @Test func theSubtitleAndSummaryFollowTheSetting() throws {
        let lib = Library(cards: [Card(id: 1, deckId: 1, native: "a", dutch: "a", box: 4, createdAt: 0)],
                          nextId: 2, decks: [Deck(id: 1, name: "Start", createdAt: 0)], nextDeckId: 2)
        var s = try #require(StudySession(library: lib, deckId: 1, box: 4, miss: .backToBoxOne))
        #expect(s.notYetSubtitle == "back to box 1")
        s.answer(known: false)
        #expect(s.summary == "Moved up to box 5: 0. Back to box 1: 1.")
        let d = try #require(StudySession(library: lib, deckId: 1, box: 4))
        #expect(d.notYetSubtitle == "back to box 3")
    }

    @Test func thePhoneSendsTheSettingToTheWatch() {
        let l = Library()
        #expect(Sync.missRule(fromContext: Sync.context(for: l, sentAt: 1, miss: .backToBoxOne)) == .backToBoxOne)
        #expect(Sync.missRule(fromContext: Sync.context(for: l, sentAt: 1)) == .oneDown)
        #expect(Sync.missRule(fromContext: ["library": Backup.encode(l)]) == nil)   // an older phone app
    }
}
