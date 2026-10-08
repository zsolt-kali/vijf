// SPEC.md → Platforms → Apple Watch: sync. The merge rule protects progress made on either device.
import Testing
@testable import VijfKit

@Suite struct SyncTests {
    func card(_ id: Int, box: Int, native: String = "w") -> Card {
        Card(id: id, deckId: 1, native: native, dutch: native, box: box, createdAt: 0)
    }
    func library(_ cards: [Card]) -> Library {
        Library(cards: cards, nextId: 99, decks: [Deck(id: 1, name: "Start", createdAt: 0)], nextDeckId: 2)
    }

    @Test func thePhoneKeepsTheHigherBox() {
        var phone = library([card(1, box: 2), card(2, box: 4), card(3, box: 1)])
        Sync.apply([.init(cardId: 1, box: 3, at: 50), .init(cardId: 2, box: 3, at: 60)], to: &phone)
        #expect(phone.card(1)?.box == 3)
        #expect(phone.card(1)?.reviewedAt == 50)
        // studied further on the phone already: unchanged
        #expect(phone.card(2)?.box == 4)
        #expect(phone.card(2)?.reviewedAt == nil)
        #expect(phone.card(3)?.box == 1)
    }

    @Test func aCardDeletedOnThePhoneStaysDeleted() {
        var phone = library([card(1, box: 1)])
        Sync.apply([.init(cardId: 7, box: 2, at: 1)], to: &phone)
        #expect(phone.cards.map(\.id) == [1])
    }

    @Test func theWatchTakesWordsAndDeletionsFromThePhoneButKeepsItsHigherBoxes() {
        let watch = library([card(1, box: 3, native: "old"), card(2, box: 1), card(3, box: 2)])
        // on the phone: card 1 edited, card 2 studied to box 2, card 3 deleted, card 4 added
        let phone = library([card(1, box: 2, native: "new"), card(2, box: 2), card(4, box: 1)])

        let merged = Sync.merge(phone: phone, into: watch)
        #expect(merged.cards.map(\.id) == [1, 2, 4])
        #expect(merged.card(1)?.native == "new")
        #expect(merged.card(1)?.box == 3)
        #expect(merged.card(2)?.box == 2)
        #expect(merged.card(4)?.box == 1)
    }

    @Test func studyingOnBothBeforeASyncLosesNothing() {
        var phone = library([card(1, box: 1), card(2, box: 1)])
        var watch = phone
        phone.answer(1, known: true, now: 10)            // phone: card 1 → 2
        watch.answer(2, known: true, now: 20)            // watch: card 2 → 2
        watch.answer(2, known: true, now: 30)            // watch: card 2 → 3
        let reviews = [2].compactMap { Sync.review(afterAnswering: $0, known: true, in: watch, now: 30) }

        Sync.apply(reviews, to: &phone)
        let watchAfter = Sync.merge(phone: phone, into: watch)
        #expect(phone.card(1)?.box == 2 && phone.card(2)?.box == 3)
        #expect(watchAfter.card(1)?.box == 2 && watchAfter.card(2)?.box == 3)
    }

    @Test func notYetSendsNothing() {
        let l = library([card(1, box: 2)])
        #expect(Sync.review(afterAnswering: 1, known: false, in: l, now: 1) == nil)
        #expect(Sync.review(afterAnswering: 1, known: true, in: l, now: 1) == .init(cardId: 1, box: 2, at: 1))
    }

    @Test func payloadsRoundTrip() {
        let l = library([card(1, box: 3)])
        #expect(Sync.library(fromContext: Sync.context(for: l)) == l)
        let reviews = [Sync.Review(cardId: 1, box: 4, at: 9)]
        #expect(Sync.reviews(fromUserInfo: Sync.userInfo(for: reviews)) == reviews)
        #expect(Sync.reviews(fromUserInfo: [:]).isEmpty)
    }

    @Test func boxesThePhoneHasNotSeenAreSentAgain() {
        let phone = library([card(1, box: 1), card(2, box: 3), card(3, box: 1)])
        var watch = library([card(1, box: 2), card(2, box: 2), card(4, box: 5)])
        watch.cards[0].reviewedAt = 77
        // card 1 is ahead on the watch; card 2 is ahead on the phone; card 4 was deleted on the phone
        #expect(Sync.unsent(phone: phone, watch: watch, now: 1) == [.init(cardId: 1, box: 2, at: 77)])
    }
}
