import Foundation
import VijfKit
import WatchConnectivity

/// The phone's side of the watch sync (SPEC.md → Platforms → Apple Watch).
///
/// After every change the phone sends its whole library as the application context (only the
/// latest one is kept, so the watch always gets the current state). The watch sends back its
/// "I know it" answers, which are applied with the highest-box rule from VijfKit.
final class PhoneSync: NSObject, WCSessionDelegate, @unchecked Sendable {
    @MainActor private weak var model: AppModel?

    @MainActor func start(with model: AppModel) {
        self.model = model
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        model.onChange = { [weak self] library in self?.push(library) }
    }

    func push(_ library: Library) {
        let session = WCSession.default
        guard WCSession.isSupported(), session.activationState == .activated,
              session.isPaired, session.isWatchAppInstalled else { return }
        try? session.updateApplicationContext(Sync.context(for: library))
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let library = self.model?.library { self.push(library) }
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
            if let library = self.model?.library { self.push(library) }
        }
    }
}
