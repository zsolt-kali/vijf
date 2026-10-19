import Foundation
import Observation
import VijfKit

enum Route: Hashable {
    case deck(Int)
    case study(deck: Int, box: Int)
    case browse(deck: Int)
    case backup
    case settings
}

/// How the last send of the library to the watch went (shown on the Backup screen).
enum WatchSyncStatus: Equatable {
    case sent(Date)
    case failed(String)
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
    /// The deck being browsed (Browse cards).
    var browse: BrowseSession?
    private(set) var toast: Toast?
    /// Called after every saved change; the watch sync uses it to send the new library.
    var onChange: ((Library, MissRule) -> Void)?
    /// What "Not yet" does above box 1. Saved next to the library (not in backups) and sent to the
    /// watch with it, so the watch always answers the way the phone is set.
    private(set) var miss: MissRule = .oneDown
    /// What the deck list shows (Settings); both on unless switched off.
    private(set) var showSearch = true
    private(set) var showStreak = true
    /// The last send to the watch, nil until one was tried (no watch paired: stays nil).
    var watchSync: WatchSyncStatus?

    private let url: URL

    init(url: URL = AppModel.defaultURL) {
        self.url = url
        if let data = try? Data(contentsOf: url), let saved = try? Backup.decode(data) {
            library = saved
        } else {
            library = .empty
        }
        if let data = try? Data(contentsOf: settingsURL), let saved = try? JSONDecoder().decode(Settings.self, from: data) {
            miss = saved.miss
            showSearch = saved.showSearch
            showStreak = saved.showStreak
        }
        launch()
        refreshDay()
    }

    /// Records today as done when nothing is due (on launch and whenever the app comes to the
    /// front, since a day can pass while it's open).
    func refreshDay() {
        if library.markDoneIfClear() { change { _ in } }
    }

    /// The settings file. The two show-switches are missing in files from before them: on.
    private struct Settings: Codable {
        var miss: MissRule
        var showSearch = true
        var showStreak = true

        init(miss: MissRule, showSearch: Bool, showStreak: Bool) {
            self.miss = miss; self.showSearch = showSearch; self.showStreak = showStreak
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            miss = try c.decodeIfPresent(MissRule.self, forKey: .miss) ?? .oneDown
            showSearch = try c.decodeIfPresent(Bool.self, forKey: .showSearch) ?? true
            showStreak = try c.decodeIfPresent(Bool.self, forKey: .showStreak) ?? true
        }
    }
    private var settingsURL: URL { url.deletingPathExtension().appendingPathExtension("settings.json") }

    private func saveSettings() {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(Settings(miss: miss, showSearch: showSearch, showStreak: showStreak))
            .write(to: settingsURL, options: .atomic)
    }

    func setMiss(_ rule: MissRule) {
        miss = rule
        saveSettings()
        onChange?(library, miss)
    }

    /// Settings → Search: the deck list's search field. Not sent to the watch, which has none.
    func setShowSearch(_ on: Bool) { showSearch = on; saveSettings() }
    /// Settings → Days in a row: the deck list's streak line and the Done for today card. Done
    /// days are recorded either way.
    func setShowStreak(_ on: Bool) { showStreak = on; saveSettings() }

    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "vijf.json")
    }

    /// Opens straight into the only deck, otherwise shows the deck list.
    func launch() {
        path = library.decks.count == 1 ? [.deck(library.decks[0].id)] : []
    }

    private func change(_ edit: (inout Library) -> Void) {
        edit(&library)
        library.markDoneIfClear()
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? Backup.encode(library).write(to: url, options: .atomic)
        onChange?(library, miss)
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

    /// Deletes a card opened from search. Undo puts it back in its place.
    func deleteCard(_ id: Int) {
        var removed: Library.DeletedCard?
        change { removed = $0.deleteCard(id) }
        guard let removed else { return }
        showUndo("Card deleted") { [weak self] in
            self?.change { $0.restore(removed) }
            self?.show("Restored")
        }
    }

    // MARK: Studying

    func startStudy(deck: Int, box: Int) {
        guard let s = StudySession(library: library, deckId: deck, box: box, miss: miss) else {
            show(library.nextNote(inDeck: deck, box: box, dayStart: Day.start()) ?? "Box \(box) is empty")
            return
        }
        study = s
        path.append(.study(deck: deck, box: box))
    }

    func answer(known: Bool) {
        guard let id = study?.currentCardId else { return }
        change { [miss] in $0.answer(id, known: known, now: .nowMillis, miss: miss) }
        study?.answer(known: known)
    }

    /// Go again, between two box 1 rounds.
    func nextRound() { study?.nextRound() }

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

    // MARK: Browsing

    /// Going through a deck's cards without answering; nil for a deck without cards.
    func startBrowse(deck: Int) {
        guard let b = BrowseSession(library: library, deckId: deck) else { return }
        browse = b
        path.append(.browse(deck: deck))
    }

    func browseNext() { browse?.next() }
    func browsePrevious() { browse?.previous() }

    /// Deletes the card being browsed; the next one takes its place. Undo puts it back and shows
    /// it again if that deck is still being browsed. The last card gone ends browsing.
    func deleteBrowsedCard() {
        guard let id = browse?.currentCardId else { return }
        var removed: Library.DeletedCard?
        change { removed = $0.deleteCard(id) }
        let at = browse?.removeCurrent() ?? 0
        let deck = browse?.deckId
        if browse?.total == 0 { browse = nil; if case .browse? = path.last { path.removeLast() } }
        guard let removed else { return }
        showUndo("Card deleted") { [weak self] in
            guard let self else { return }
            change { $0.restore(removed) }
            if var b = browse, b.deckId == deck, path.last == .browse(deck: b.deckId) {
                b.reinsert(removed.card.id, at: at)
                browse = b
            }
            show("Restored")
        }
    }

    // MARK: Watch

    /// The watch's answers; a card keeps the higher of the two boxes and the later `seenAt`.
    /// The watch's answers, and the days it finished, which count here too.
    func applyReviews(_ reviews: [Sync.Review], doneDays: [String] = []) {
        change {
            Sync.apply(reviews, to: &$0)
            Sync.addDoneDays(doneDays, to: &$0)
        }
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
