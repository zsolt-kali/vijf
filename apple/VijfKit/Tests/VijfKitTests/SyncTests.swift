// SPEC.md → Platforms → Apple Watch: sync. The latest answer to a card wins, on either device.
import Foundation
import Testing
@testable import VijfKit

@Suite struct SyncTests {
    func card(_ id: Int, box: Int, native: String = "w", seenAt: Int64? = nil) -> Card {
        Card(id: id, deckId: 1, native: native, dutch: native, box: box, createdAt: 0, seenAt: seenAt)
    }
    func library(_ cards: [Card]) -> Library {
        Library(cards: cards, nextId: 99, decks: [Deck(id: 1, name: "Start", createdAt: 0)], nextDeckId: 2)
    }

    @Test func thePhoneTakesAnswersNewerThanItsOwn() {
        var phone = library([card(1, box: 2), card(2, box: 4, seenAt: 70)])
        Sync.apply([.init(cardId: 1, box: 3, at: 50, known: true), .init(cardId: 2, box: 3, at: 60, known: true)], to: &phone)
        #expect(phone.card(1)?.box == 3)
        #expect(phone.card(1)?.seenAt == 50 && phone.card(1)?.reviewedAt == 50)
        // answered later on the phone already: unchanged
        #expect(phone.card(2)?.box == 4)
        #expect(phone.card(2)?.seenAt == 70 && phone.card(2)?.reviewedAt == nil)
    }

    @Test func aCardMissedOnTheWatchGoesDownABoxOnThePhoneToo() {
        var phone = library([card(1, box: 5, seenAt: 10)])
        var watch = phone
        watch.answer(1, known: false, now: 40)
        let review = Sync.review(afterAnswering: 1, known: false, in: watch, now: 40)!
        #expect(review == .init(cardId: 1, box: 4, at: 40, known: false))
        Sync.apply([review], to: &phone)
        #expect(phone.card(1)?.box == 4)
        #expect(phone.card(1)?.reviewedAt == nil)
        // and the watch keeps it there when the phone's copy comes back
        #expect(Sync.merge(phone: phone, into: watch).card(1)?.box == 4)
    }

    @Test func applyingAnAnswerTwiceChangesNothing() {
        var phone = library([card(1, box: 1)])
        let reviews: [Sync.Review] = [.init(cardId: 1, box: 2, at: 50, known: true)]
        Sync.apply(reviews, to: &phone)
        let once = phone
        Sync.apply(reviews, to: &phone)
        #expect(phone == once)
        // an older answer arriving late changes nothing either
        Sync.apply([.init(cardId: 1, box: 1, at: 30, known: false)], to: &phone)
        #expect(phone == once)
    }

    @Test func answersArrivingOutOfOrderEndWithTheLatest() {
        var phone = library([card(1, box: 1)])
        Sync.apply([.init(cardId: 1, box: 3, at: 90, known: true), .init(cardId: 1, box: 2, at: 50, known: true)], to: &phone)
        #expect(phone.card(1)?.box == 3 && phone.card(1)?.seenAt == 90)
    }

    @Test func aReviewFromAnOlderWatchAppCountsAsKnownWhenTheBoxWentUp() throws {
        let json = #"[{"cardId":1,"box":2,"at":50},{"cardId":2,"box":1,"at":50}]"#
        let reviews = try JSONDecoder().decode([Sync.Review].self, from: Data(json.utf8))
        var phone = library([card(1, box: 1), card(2, box: 1)])
        Sync.apply(reviews, to: &phone)
        #expect(phone.card(1)?.box == 2 && phone.card(1)?.reviewedAt == 50)
        #expect(phone.card(2)?.box == 1 && phone.card(2)?.reviewedAt == nil)
    }

    @Test func aCardDeletedOnThePhoneStaysDeleted() {
        var phone = library([card(1, box: 1)])
        Sync.apply([.init(cardId: 7, box: 2, at: 1, known: true)], to: &phone)
        #expect(phone.cards.map(\.id) == [1])
    }

    @Test func theWatchTakesWordsAndDeletionsFromThePhoneButKeepsItsLaterAnswers() {
        let watch = library([card(1, box: 3, native: "old", seenAt: 50), card(2, box: 1, seenAt: 10), card(3, box: 2)])
        // on the phone: card 1 edited, card 2 studied to box 2, card 3 deleted, card 4 added
        let phone = library([card(1, box: 2, native: "new", seenAt: 20), card(2, box: 2, seenAt: 30), card(4, box: 1)])

        let merged = Sync.merge(phone: phone, into: watch)
        #expect(merged.cards.map(\.id) == [1, 2, 4])
        #expect(merged.card(1)?.native == "new")
        #expect(merged.card(1)?.box == 3 && merged.card(1)?.seenAt == 50)
        #expect(merged.card(2)?.box == 2 && merged.card(2)?.seenAt == 30)
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
        #expect(phone.card(2) == watchAfter.card(2))
    }

    @Test func everyAnswerIsSentWithTheCardsBox() {
        let l = library([card(1, box: 2)])
        #expect(Sync.review(afterAnswering: 1, known: false, in: l, now: 1) == .init(cardId: 1, box: 2, at: 1, known: false))
        #expect(Sync.review(afterAnswering: 9, known: true, in: l, now: 1) == nil)
    }

    @Test func aCardSeenOnTheWatchIsNotDueOnThePhoneTheSameDay() {
        var phone = library([card(1, box: 2)])
        var watch = phone
        watch.answer(1, known: false, now: noon())                  // Not yet on the watch
        Sync.apply([Sync.review(afterAnswering: 1, known: false, in: watch, now: noon())!], to: &phone)
        #expect(phone.card(1)?.box == 1)
        #expect(phone.card(1)?.seenAt == noon())
        #expect(phone.card(1)?.reviewedAt == nil)
        #expect(!phone.card(1)!.isDue(dayStart: midnight()))
    }

    @Test func answersThePhoneHasNotSeenAreSentAgain() {
        let phone = library([card(1, box: 1), card(2, box: 3, seenAt: 90), card(3, box: 1)])
        var watch = library([card(1, box: 2), card(2, box: 2, seenAt: 60), card(3, box: 1, seenAt: 40), card(4, box: 5, seenAt: 99)])
        watch.answer(1, known: true, now: 77)
        // card 1 known and card 3 Not yet on the watch; card 2 answered later on the phone; card 4 deleted there
        #expect(Sync.unsent(phone: phone, watch: watch) == [
            .init(cardId: 1, box: 3, at: 77, known: true), .init(cardId: 3, box: 1, at: 40, known: false),
        ])
    }

    @Test func payloadsRoundTrip() {
        let l = library([card(1, box: 3)])
        #expect(Sync.library(fromContext: Sync.context(for: l, sentAt: 1)) == l)
        // Each send is a different context, so an unchanged library is still delivered again.
        #expect(Sync.context(for: l, sentAt: 1)["sentAt"] as? Int64 != Sync.context(for: l, sentAt: 2)["sentAt"] as? Int64)
        let reviews = [Sync.Review(cardId: 1, box: 4, at: 9, known: false)]
        #expect(Sync.reviews(fromUserInfo: Sync.userInfo(for: reviews)) == reviews)
        #expect(Sync.reviews(fromUserInfo: [:]).isEmpty)
    }
}
