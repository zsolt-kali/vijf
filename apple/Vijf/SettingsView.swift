import SwiftUI
import VijfKit

/// The iPhone's settings (SPEC.md → Settings): one switch, Classic Leitner, for what "Not yet"
/// does above box 1. The watch follows whatever is set here.
struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let on = Binding(get: { model.miss == .backToBoxOne },
                         set: { model.setMiss($0 ? .backToBoxOne : .oneDown) })
        ScrollView {
            Toggle(isOn: on) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Classic Leitner").font(.vjLabel).foregroundStyle(VJ.ink)
                    Eyebrow(on.wrappedValue ? "Missed cards go back to box 1" : "Missed cards go down one box")
                }
            }
            .toggleStyle(VJSwitchStyle())
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(VJ.card)
            .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
            .padding(16)
        }
        .background(VJ.paper)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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
