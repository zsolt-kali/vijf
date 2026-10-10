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
        model.onChange = { sent = $0 }

        model.applyReviews([Sync.Review(cardId: id, box: 3, at: 42)])
        #expect(model.library.card(id)?.box == 3)
        #expect(sent?.card(id)?.box == 3)
        #expect(AppModel(url: url).library.card(id)?.box == 3)
    }
}
