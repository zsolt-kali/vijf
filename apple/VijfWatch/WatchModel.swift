import Foundation
import Observation
import VijfKit
import WatchConnectivity

/// The watch's state: its own copy of the library (so studying works without the phone),
/// the study session in progress, and the connection to the phone.
///
/// The phone sends its whole library; the watch merges it in (VijfKit's `Sync.merge`), keeping
/// any box it has moved further. Each "I know it" goes back to the phone as a review, queued by
/// WatchConnectivity until the phone is reachable.
@MainActor @Observable
final class WatchModel {
    private(set) var library: Library
    var study: StudySession?

    private let url: URL
    private let link = PhoneLink()
    /// The last library the phone sent, to tell which of the watch's answers it hasn't applied.
    private var lastFromPhone: Library?

    init(url: URL = URL.applicationSupportDirectory.appending(path: "vijf.json")) {
        self.url = url
        library = (try? Data(contentsOf: url)).flatMap { try? Backup.decode($0) } ?? .empty
        link.onLibrary = { [weak self] phone in self?.receive(phone) }
        link.onReachable = { [weak self] in self?.sendUnsent() }
        link.start()
    }

    struct BoxItem: Identifiable {
        let deck: Deck
        let box: Int
        let count: Int
        var id: String { "\(deck.id)-\(box)" }
    }

    /// Every deck and box that has cards, in deck order then box order.
    var boxes: [BoxItem] {
        library.decks.flatMap { deck in
            (1...5).compactMap { box in
                let n = library.cards(inDeck: deck.id, box: box).count
                return n > 0 ? BoxItem(deck: deck, box: box, count: n) : nil
            }
        }
    }

    func receive(_ phone: Library) {
        lastFromPhone = phone
        sendUnsent()
        save(Sync.merge(phone: phone, into: library))
    }

    /// Re-sends every box the watch holds higher than the phone's last copy. Applying an answer
    /// twice is harmless (the higher box wins), so this runs whenever the phone may have missed one.
    func sendUnsent() {
        guard let phone = lastFromPhone else { return }
        let unsent = Sync.unsent(phone: phone, watch: library, now: .nowMillis)
        if !unsent.isEmpty { link.send(unsent) }
    }

    func startStudy(deck: Int, box: Int) {
        study = StudySession(library: library, deckId: deck, box: box)
    }

    func answer(known: Bool) {
        guard let id = study?.currentCardId else { return }
        var l = library
        l.answer(id, known: known, now: .nowMillis)
        save(l)
        if let review = Sync.review(afterAnswering: id, known: known, in: l, now: .nowMillis) {
            link.send([review])
        }
        study?.answer(known: known)
    }

    func next() { study?.next() }

    private func save(_ l: Library) {
        library = l
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? Backup.encode(l).write(to: url, options: .atomic)
    }
}

/// The WatchConnectivity side of the watch app.
private final class PhoneLink: NSObject, WCSessionDelegate, @unchecked Sendable {
    @MainActor var onLibrary: ((Library) -> Void)?
    @MainActor var onReachable: (() -> Void)?

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends answers straight away when the phone app is reachable; otherwise, or if that fails,
    /// queues them with transferUserInfo, which the system delivers when the phone is back.
    func send(_ reviews: [Sync.Review]) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let info = Sync.userInfo(for: reviews)
        if session.isReachable {
            session.sendMessage(info, replyHandler: nil) { _ in session.transferUserInfo(info) }
        } else {
            session.transferUserInfo(info)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        // The latest library the phone sent while the watch app wasn't running.
        deliver(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        deliver(context)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor in self.onReachable?() }
    }

    private func deliver(_ context: [String: Any]) {
        guard let library = Sync.library(fromContext: context) else { return }
        Task { @MainActor in self.onLibrary?(library) }
    }
}
