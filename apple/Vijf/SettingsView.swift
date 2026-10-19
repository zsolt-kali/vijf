import SwiftUI
import VijfKit

/// The iPhone's settings (SPEC.md → Settings): Classic Leitner (what "Not yet" does above box 1;
/// the watch follows it), and what the deck list shows: Search and Days in a row.
struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                row("Classic Leitner",
                    Binding(get: { model.miss == .backToBoxOne }, set: { model.setMiss($0 ? .backToBoxOne : .oneDown) }),
                    on: "Missed cards go back to box 1", off: "Missed cards go down one box")
                row("Search", Binding(get: { model.showSearch }, set: { model.setShowSearch($0) }),
                    on: "Shown on the deck list", off: "Hidden")
                row("Days in a row", Binding(get: { model.showStreak }, set: { model.setShowStreak($0) }),
                    on: "Shown on the deck list", off: "Hidden")
            }
            .padding(16)
        }
        .background(VJ.paper)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// One setting: its name, a line saying what the current position does, and the switch.
    private func row(_ label: String, _ isOn: Binding<Bool>, on: String, off: String) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.vjLabel).foregroundStyle(VJ.ink)
                Eyebrow(isOn.wrappedValue ? on : off)
            }
        }
        .toggleStyle(VJSwitchStyle())
        .padding(.vertical, 14).padding(.horizontal, 16)
        .background(VJ.card)
        .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
    }
}

/// vijf's square switch: an `ink` outline; off, a `paper` track with the `ink` knob on the left;
/// on, an `ink` track with the `on-ink` knob on the right.
struct VJSwitchStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let on = configuration.isOn
        return HStack(spacing: 12) {
            configuration.label
            Spacer(minLength: 0)
            ZStack(alignment: on ? .trailing : .leading) {
                Rectangle().fill(on ? VJ.ink : VJ.paper)
                Rectangle().fill(on ? VJ.onInk : VJ.ink).frame(width: 23, height: 23).padding(3)
            }
            .frame(width: 56, height: 32)
            .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) { configuration.isOn.toggle() } }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(on ? "On" : "Off")
        .accessibilityAction { configuration.isOn.toggle() }
    }
}
