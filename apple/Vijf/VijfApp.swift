import SwiftUI

@main
struct VijfApp: App {
    @State private var model: AppModel
    @Environment(\.scenePhase) private var phase
    private let sync = PhoneSync()

    /// The watch sync starts with the app, not with its first screen: iOS can launch the app in
    /// the background to hand over the watch's answers, and then no screen appears.
    init() {
        let model = AppModel()
        _model = State(initialValue: model)
        sync.start(with: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
        .onChange(of: phase) {
            if phase == .active {
                model.refreshDay()
                sync.push(model.library, miss: model.miss)
            }
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.path) {
            DecksView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .deck(let id): DeckView(deckId: id)
                    case .study(let deck, let box): StudyView(deckId: deck, box: box)
                    case .browse(let deck): BrowseView(deckId: deck)
                    case .backup: BackupView()
                    case .settings: SettingsView()
                    }
                }
        }
        .tint(VJ.ink)
        .overlay(alignment: .bottom) { ToastView() }
    }
}

/// The toast at the bottom: ink fill, mono uppercase text, Undo in the accent colour.
struct ToastView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let toast = model.toast {
            HStack(spacing: 16) {
                Text(toast.message.uppercased())
                if toast.undo != nil {
                    Button("UNDO") { model.undoToast() }
                        .fontWeight(.bold)
                        .foregroundStyle(VJ.onInkAccent)
                }
            }
            .font(.vjMono(11)).tracking(1.1)
            .foregroundStyle(VJ.onInk)
            .padding(.horizontal, 16).padding(.vertical, 11)
            .background(VJ.ink)
            .padding(.bottom, 22)
            .transition(.opacity)
            .id(toast.id)
        }
    }
}
