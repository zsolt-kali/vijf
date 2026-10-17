import SwiftUI
import VijfKit

/// The iPhone's settings (SPEC.md → Leitner rules): what "Not yet" does above box 1. The watch
/// follows whatever is set here.
struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("When you don't know a card").padding(.top, 8)
                choice(.oneDown, title: "Move it down one box", sub: "As now")
                choice(.backToBoxOne, title: "Send it back to box 1", sub: "Classic Leitner")
                Text("Either way the card comes back tomorrow. Box 1 cards stay in box 1. The watch follows this setting.")
                    .font(.vjNote).foregroundStyle(VJ.mute).padding(.top, 10)
            }
            .padding(16)
        }
        .background(VJ.paper)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func choice(_ rule: MissRule, title: String, sub: String) -> some View {
        let on = model.miss == rule
        return Button { model.setMiss(rule) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.vjLabel).foregroundStyle(VJ.ink)
                    Eyebrow(sub)
                }
                Spacer()
                if on { Eyebrow("In use", color: VJ.ink) }
            }
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(VJ.card)
            .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
