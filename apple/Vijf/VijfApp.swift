import SwiftUI

@main
struct VijfApp: App {
    @State private var model = AppModel()
    private let sync = PhoneSync()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task { sync.start(with: model) }
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
                    case .backup: BackupView()
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
