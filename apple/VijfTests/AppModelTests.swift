// The app's wiring of VijfKit: undo, navigation and saving (SPEC.md → Editing a card, Decks).
import Foundation
import Testing
@testable import Vijf
import VijfKit

@MainActor
@Suite struct AppModelTests {
    func freshModel() -> AppModel {
        AppModel(url: URL.temporaryDirectory.appending(path: "vijf-\(UUID().uuidString).json"))
    }

    @Test func undoAfterDeletingACardWhileStudyingMakesItCurrentAgain() throws {
        let model = freshModel()
        model.addStarterSet()
        let deckId = try #require(model.library.decks.first?.id)
        model.startStudy(deck: deckId, box: 1)
        model.answer(known: false)
        let id = try #require(model.study?.currentCardId)

        model.deleteCurrentCard()
        #expect(model.library.card(id) == nil)
        #expect(model.study?.position == 2)
        #expect(model.study?.total == 11)
        #expect(model.toast?.undo != nil)

        model.undoToast()
        #expect(model.library.card(id) != nil)
        #expect(model.study?.currentCardId == id)
        #expect(model.study?.position == 2)
        #expect(model.study?.total == 12)
        #expect(model.toast?.message == "Restored")
    }

    @Test func aBoxStudiedTodayIsDoneUntilTomorrow() throws {
        let model = freshModel()
        model.addStarterSet()
        let deckId = try #require(model.library.decks.first?.id)
        model.startStudy(deck: deckId, box: 1)
        for _ in 0..<12 { model.answer(known: false) }
        model.study = nil
        model.startStudy(deck: deckId, box: 1)
        #expect(model.study == nil)
        #expect(model.toast?.message == "Next tomorrow")
        model.startStudy(deck: deckId, box: 2)
        #expect(model.toast?.message == "Box 2 is empty")
    }

    @Test func goAgainStartsTheNextBox1Round() throws {
        let model = freshModel()
        model.addStarterSet()
        let deckId = try #require(model.library.decks.first?.id)
        model.startStudy(deck: deckId, box: 1)
        model.answer(known: true)
        for _ in 0..<11 { model.answer(known: false) }
        #expect(model.study?.isBetweenRounds == true)
        #expect(model.study?.retry.count == 11)
        model.nextRound()
        #expect(model.study?.round == 2)
        #expect(model.study?.position == 1 && model.study?.total == 11)
    }

    @Test func browsingGoesThroughTheDeckWithoutChangingIt() throws {
        let model = freshModel()
        model.addStarterSet()
        let deckId = try #require(model.library.decks.first?.id)
        let before = model.library
        model.startBrowse(deck: deckId)
        #expect(model.path.last == .browse(deck: deckId))
        #expect(model.browse?.position == 1 && model.browse?.total == 12)
        model.browseNext(); model.browseNext()
        #expect(model.browse?.position == 3)
        #expect(model.library == before)
    }

    @Test func deletingWhileBrowsingShowsTheNextCardAndUndoBringsItBack() throws {
        let model = freshModel()
        model.addStarterSet()
        let deckId = try #require(model.library.decks.first?.id)
        model.startBrowse(deck: deckId)
        model.browseNext()
        let id = try #require(model.browse?.currentCardId)
        model.deleteBrowsedCard()
        #expect(model.library.card(id) == nil)
        #expect(model.browse?.total == 11 && model.browse?.position == 2)
        model.undoToast()
        #expect(model.library.card(id) != nil)
        #expect(model.browse?.currentCardId == id && model.browse?.total == 12)
    }

    @Test func aDeckWithoutCardsCannotBeBrowsed() throws {
        let model = freshModel()
        _ = model.makeDeck(named: "Leeg")
        let deckId = try #require(model.library.decks.first?.id)
        model.startBrowse(deck: deckId)
        #expect(model.browse == nil)
    }

    @Test func theNotYetSettingIsKeptAndUsedAndSentToTheWatch() throws {
        let url = URL.temporaryDirectory.appending(path: "vijf-\(UUID().uuidString).json")
        let model = AppModel(url: url)
        let backup = Library(cards: [Card(id: 1, deckId: 1, native: "a", dutch: "a", box: 4, createdAt: 0)],
                             nextId: 2, decks: [Deck(id: 1, name: "Start", createdAt: 0)], nextDeckId: 2)
        #expect(model.restore(from: String(decoding: Backup.encode(backup), as: UTF8.self)))
        let deckId = 1, id = 1
        var sent: MissRule?
        model.onChange = { _, miss in sent = miss }
        model.setMiss(.backToBoxOne)
        #expect(sent == .backToBoxOne)
        #expect(AppModel(url: url).miss == .backToBoxOne)

        model.startStudy(deck: deckId, box: 4)
        #expect(model.study?.notYetSubtitle == "back to box 1")
        model.answer(known: false)
        #expect(model.library.card(id)?.box == 1)
    }

    @Test func undoAfterLeavingTheSessionOnlyRestoresTheCard() throws {
        let model = freshModel()
        model.addStarterSet()
        let deckId = try #require(model.library.decks.first?.id)
        model.startStudy(deck: deckId, box: 1)
        let id = try #require(model.study?.currentCardId)
        model.deleteCurrentCard()
        model.path.removeLast()

        model.undoToast()
        #expect(model.library.card(id)?.box == 1)
        #expect(model.study?.currentCardId != id)
    }

    @Test func deletingADeckCanBeUndone() throws {
        let model = freshModel()
        #expect(model.makeDeck(named: "Eten") == nil)
        #expect(model.makeDeck(named: "Werk") == nil)
        let eten = try #require(model.library.deck(named: "Eten"))
        _ = model.addCard(native: "bread", dutch: "brood", to: eten.id)

        model.deleteDeck(eten.id)
        #expect(model.library.decks.map(\.name) == ["Werk"])
        model.undoToast()
        #expect(model.library.decks.map(\.name) == ["Eten", "Werk"])
        #expect(model.library.cards(inDeck: eten.id).count == 1)
    }

    @Test func deletingACardFoundBySearchCanBeUndone() throws {
        let model = freshModel()
        model.addStarterSet()
        let hit = try #require(Search.cards(matching: "brood", in: model.library).first)

        model.deleteCard(hit.card.id)
        #expect(model.library.card(hit.card.id) == nil)
        #expect(model.toast?.undo != nil)

        model.undoToast()
        #expect(model.library.card(hit.card.id) == hit.card)
        #expect(model.library.cards.count == 12)
    }

    @Test func theDutchWordIsReadInDutch() {
        let u = DutchVoice.utterance(for: "het huis")
        #expect(u.speechString == "het huis")
        #expect(u.voice?.language.hasPrefix("nl") ?? true)
    }

    @Test func deckNamesAreValidated() {
        let model = freshModel()
        #expect(model.makeDeck(named: "  ") == "Give the deck a name")
        #expect(model.makeDeck(named: "Eten") == nil)
        #expect(model.makeDeck(named: "eten") == "That deck already exists")
    }

    @Test func withOneDeckTheAppOpensStraightIntoIt() throws {
        let url = URL.temporaryDirectory.appending(path: "vijf-\(UUID().uuidString).json")
        let first = AppModel(url: url)
        first.addStarterSet()
        let reopened = AppModel(url: url)
        let id = try #require(reopened.library.decks.first?.id)
        #expect(reopened.path == [.deck(id)])
        #expect(reopened.library.cards.count == 12)
    }

    @Test func aWebAppBackupRestoresAndAnInvalidOneIsRejected() {
        let model = freshModel()
        #expect(!model.restore(from: "not a backup"))
        #expect(model.toast?.message == "Invalid backup")
        let web = #"{"cards":[{"id":1,"native":"the house","dutch":"het huis","box":3,"createdAt":1,"reviewedAt":2}],"nextId":2}"#
        #expect(model.restore(from: web))
        #expect(model.library.decks.map(\.name) == ["Start"])
        #expect(model.library.card(1)?.box == 3)
    }
}

@MainActor
@Suite struct WatchReviewTests {
    @Test func watchAnswersRaiseBoxesAndAreSaved() throws {
        let url = URL.temporaryDirectory.appending(path: "vijf-\(UUID().uuidString).json")
        let model = AppModel(url: url)
        model.addStarterSet()
        let id = try #require(model.library.cards.first?.id)
        var sent: Library?
        model.onChange = { library, _ in sent = library }

        model.applyReviews([Sync.Review(cardId: id, box: 3, at: 42, known: true)])
        #expect(model.library.card(id)?.box == 3)
        #expect(sent?.card(id)?.box == 3)
        #expect(AppModel(url: url).library.card(id)?.box == 3)
    }
}
