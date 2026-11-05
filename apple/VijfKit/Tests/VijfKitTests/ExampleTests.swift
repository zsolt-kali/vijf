// SPEC.md → Example sentences, Bulk import format
import Testing
@testable import VijfKit

@Suite struct ExampleTests {
    @Test func cardsKeepTheirSentencesTrimmedAndEmptyMeansNone() throws {
        var l = Library()
        let added = l.addCard(native: "the house", dutch: "het huis", nativeExample: " The house is big. ", dutchExample: "", to: 1, now: 1)
        let c = try #require(added)
        #expect(c.nativeExample == "The house is big." && c.dutchExample == nil)
        var saved = l.editCard(c.id, native: "the house", dutch: "het huis", nativeExample: nil, dutchExample: "Het huis is groot.")
        #expect(saved)
        #expect(l.card(c.id)?.nativeExample == "The house is big.")       // nil keeps it
        saved = l.editCard(c.id, native: "the house", dutch: "het huis", nativeExample: "", dutchExample: nil)
        #expect(saved)
        #expect(l.card(c.id)?.nativeExample == nil)                         // empty removes it
        #expect(l.card(c.id)?.dutchExample == "Het huis is groot.")
    }

    @Test func sentencesAreSavedAndOldDataHasNone() throws {
        let l = Library(cards: [Card(id: 1, deckId: 1, native: "a", dutch: "b", createdAt: 0, dutchExample: "Een zin.")], nextId: 2,
                        decks: [Deck(id: 1, name: "Start", createdAt: 0)], nextDeckId: 2)
        let json = String(decoding: Backup.encode(l), as: UTF8.self)
        #expect(json.contains(#""dutchExample":"Een zin.""#) && !json.contains("nativeExample"))
        #expect(try Backup.decode(Backup.encode(l)) == l)
        let old = try Backup.decode(#"{"cards":[{"id":1,"deckId":1,"native":"a","dutch":"b","box":1,"createdAt":0}],"decks":[{"id":1,"name":"Start","createdAt":0}]}"#)
        #expect(old.cards[0].nativeExample == nil && old.cards[0].dutchExample == nil)
    }

    @Test func importLinesWithSentences() {
        let e = BulkImport.entries(from: """
        the house | The house is big. = het huis | Het huis is groot.
        the bread = het brood | Het brood is vers.
        the cheese = de kaas
        the house | het huis
        = geen woord | Zin.
        a | x = b | y | z
        """)
        #expect(e.count == 5)
        #expect(e[0] == .init(native: "the house", dutch: "het huis", nativeExample: "The house is big.", dutchExample: "Het huis is groot."))
        #expect(e[1] == .init(native: "the bread", dutch: "het brood", nativeExample: nil, dutchExample: "Het brood is vers."))
        #expect(e[2] == .init(native: "the cheese", dutch: "de kaas", nativeExample: nil, dutchExample: nil))
        // no "=": "|" still separates the languages, as before
        #expect(e[3] == .init(native: "the house", dutch: "het huis", nativeExample: nil, dutchExample: nil))
        #expect(e[4] == .init(native: "a", dutch: "b", nativeExample: "x", dutchExample: "y"))
    }

    @Test func theWordIsFoundInItsSentenceIgnoringCaseAndAccents() {
        let s = "Het huis is groot."
        #expect(ExampleMark.range(of: "het huis", in: s).map { String(s[$0]) } == "Het huis")
        #expect(ExampleMark.range(of: "café", in: "Ik zit in een cafe.") != nil)
        #expect(ExampleMark.range(of: "werken", in: "Ik werk hier graag.") == nil)
    }

    @Test func theStarterWordsHaveSentences() {
        var l = Library()
        l.addStarterSet(now: 1)
        #expect(l.cards.allSatisfy { $0.nativeExample != nil && $0.dutchExample != nil })
    }
}
