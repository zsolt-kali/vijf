import Foundation
import Observation
import VijfKit

enum Route: Hashable {
    case deck(Int)
    case study(deck: Int, box: Int)
    case backup
}

/// A short confirmation at the bottom of the screen, optionally with Undo.
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let undo: (@MainActor () -> Void)?

    static func == (a: Toast, b: Toast) -> Bool { a.id == b.id }
}

/// The app's state: the library (saved on every change), navigation, the study session in
/// progress and the toast. All rules live in VijfKit; this only wires them to the screens.
@MainActor @Observable
final class AppModel {
    private(set) var library: Library
    var path: [Route] = []
    var study: StudySession?
    private(set) var toast: Toast?
    /// Called after every saved change; the watch sync uses it to send the new library.
    var onChange: ((Library) -> Void)?

    private let url: URL

    init(url: URL = AppModel.defaultURL) {
        self.url = url
        if let data = try? Data(contentsOf: url), let saved = try? Backup.decode(data) {
            library = saved
        } else {
            library = .empty
        }
        launch()
    }

    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "vijf.json")
    }

    /// Opens straight into the only deck, otherwise shows the deck list.
    func launch() {
        path = library.decks.count == 1 ? [.deck(library.decks[0].id)] : []
    }

    private func change(_ edit: (inout Library) -> Void) {
        edit(&library)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? Backup.encode(library).write(to: url, options: .atomic)
        onChange?(library)
    }

    // MARK: Toasts

    func show(_ message: String) { present(Toast(message: message, undo: nil), for: .seconds(1.8)) }

    /// Only one undo is pending at a time: a newer toast replaces it.
    func showUndo(_ message: String, undo: @escaping @MainActor () -> Void) {
        present(Toast(message: message, undo: undo), for: .seconds(5))
    }

    func undoToast() {
        guard let undo = toast?.undo else { return }
        toast = nil
        undo()
    }

    private func present(_ t: Toast, for duration: Duration) {
        toast = t
        Task { [weak self] in
            try? await Task.sleep(for: duration)
            if self?.toast?.id == t.id { self?.toast = nil }
        }
    }

    // MARK: Decks

    /// Returns an error message to show, or nil when the deck was created and opened.
    func makeDeck(named name: String) -> String? {
        var made: Deck?
        var failure: String?
        change { l in
            do { made = try l.makeDeck(named: name, now: .nowMillis) }
            catch { failure = (error as? Library.DeckNameError) == .empty ? "Give the deck a name" : "That deck already exists" }
        }
        if let made { path = [.deck(made.id)]; show("Deck created") }
        return failure
    }

    func deleteDeck(_ id: Int) {
        var removed: Library.DeletedDeck?
        change { removed = $0.deleteDeck(id) }
        guard let removed else { return }
        showUndo("Deck deleted") { [weak self] in
            self?.change { $0.restore(removed) }
            self?.show("Restored")
        }
    }

    func addStarterSet() {
        var start: Deck?
        change { start = $0.addStarterSet(now: .nowMillis) }
        if let start { path = [.deck(start.id)] }
        show("12 words added to box 1")
    }

    // MARK: Cards

    func addCard(native: String, dutch: String, to deckId: Int) -> Bool {
        var added = false
        change { added = $0.addCard(native: native, dutch: dutch, to: deckId, now: .nowMillis) != nil }
        show(added ? "Added to box 1" : "Fill in both fields")
        return added
    }

    func importList(_ text: String, to deckId: Int) -> Bool {
        let pairs = BulkImport.pairs(from: text)
        guard !pairs.isEmpty else { show("No valid lines found"); return false }
        change { l in for p in pairs { l.addCard(native: p.native, dutch: p.dutch, to: deckId, now: .nowMillis) } }
        show("\(pairs.count) words added")
        return true
    }

    func editCard(_ id: Int, native: String, dutch: String) -> Bool {
        var saved = false
        change { saved = $0.editCard(id, native: native, dutch: dutch) }
        show(saved ? "Saved" : "Fill in both fields")
        return saved
    }

    // MARK: Studying

    func startStudy(deck: Int, box: Int) {
        guard let s = StudySession(library: library, deckId: deck, box: box) else {
            show("Box \(box) is empty")
            return
        }
        study = s
        path.append(.study(deck: deck, box: box))
    }

    func answer(known: Bool) {
        guard let id = study?.currentCardId else { return }
        change { $0.answer(id, known: known, now: .nowMillis) }
        study?.answer(known: known)
    }

    func next() { study?.next() }

    /// Deletes the card being studied and moves on. Undo puts it back, and makes it the current
    /// card again if that session is still running.
    func deleteCurrentCard() {
        guard let id = study?.currentCardId else { return }
        var removed: Library.DeletedCard?
        change { removed = $0.deleteCard(id) }
        study?.removeCurrent()
        let session = study
        guard let removed else { return }
        showUndo("Card deleted") { [weak self] in
            guard let self else { return }
            change { $0.restore(removed) }
            if var s = study, s.deckId == session?.deckId, s.box == session?.box, path.last == .study(deck: s.deckId, box: s.box) {
                s.reinsert(removed.card.id)
                study = s
            }
            show("Restored")
        }
    }

    // MARK: Watch

    /// The watch's "I know it" answers; a card keeps the higher of the two boxes.
    func applyReviews(_ reviews: [Sync.Review]) {
        change { Sync.apply(reviews, to: &$0) }
    }

    // MARK: Backup

    var backupText: String { Backup.text(library) }

    /// Replaces everything with the pasted backup. Returns false when the text is invalid.
    func restore(from text: String) -> Bool {
        guard let restored = try? Backup.decode(text) else { show("Invalid backup"); return false }
        toast = nil
        change { $0 = restored }
        study = nil
        launch()
        show("Restored")
        return true
    }
}
