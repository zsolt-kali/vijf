import Foundation
import VijfKit
import WatchConnectivity

/// The phone's side of the watch sync (SPEC.md → Platforms → Apple Watch).
///
/// The phone sends its whole library as the application context (only the latest one is kept, so
/// the watch always gets the current state): when the session activates, after every change, and
/// whenever the app comes to the front. The watch sends back its answers, which are
/// applied with the latest-answer rule from VijfKit. The "Not yet" setting travels with the library. The outcome of the last send is kept on the
/// model (`watchSync`) and shown on the Backup screen, so a stuck sync is visible.
final class PhoneSync: NSObject, WCSessionDelegate, @unchecked Sendable {
    @MainActor private weak var model: AppModel?

    @MainActor func start(with model: AppModel) {
        self.model = model
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        model.onChange = { [weak self] library, miss in self?.push(library, miss: miss) }
    }

    /// No `isWatchAppInstalled` pre-check: it has wrongly said no after the watch app was
    /// installed on its own, and the phone then stopped sending without a sign. Trying costs
    /// nothing; a real failure is reported instead.
    func push(_ library: Library, miss: MissRule) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired else { return }
        do {
            try session.updateApplicationContext(Sync.context(for: library, sentAt: .nowMillis, miss: miss))
            report(.sent(Date()))
        } catch {
            report(.failed(error.localizedDescription))
        }
    }

    private func report(_ status: WatchSyncStatus) {
        Task { @MainActor in self.model?.watchSync = status }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let model = self.model { self.push(model.library, miss: model.miss) }
        }
    }

    /// Queued answers (delivered whenever the phone is reachable again).
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        receive(userInfo)
    }

    /// Answers sent straight away while both apps are running.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(message)
    }

    private func receive(_ payload: [String: Any]) {
        let reviews = Sync.reviews(fromUserInfo: payload)
        guard !reviews.isEmpty else { return }
        Task { @MainActor in self.model?.applyReviews(reviews) }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // The user switched to another watch: reconnect to the new one.
        WCSession.default.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            if let model = self.model { self.push(model.library, miss: model.miss) }
        }
    }
}
