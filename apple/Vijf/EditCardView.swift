import SwiftUI
import VijfKit

/// Fixing or deleting the card being studied (SPEC.md → Editing a card).
struct EditCardView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let card: Card
    @State private var native: String
    @State private var dutch: String

    init(card: Card) {
        self.card = card
        _native = State(initialValue: card.native)
        _dutch = State(initialValue: card.dutch)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack { Eyebrow("Edit", color: VJ.ink, size: 11); Spacer() }
            VStack(spacing: 14) {
                VJField(label: "Your language", text: $native).onSubmit(save)
                VJField(label: "Dutch", text: $dutch).onSubmit(save)
            }
            .padding(22)
            .background(VJ.card)
            .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))

            HStack(spacing: 8) {
                Button("Cancel") { dismiss() }.buttonStyle(.vj())
                Button("Save", action: save).buttonStyle(.vj(.fill))
            }
            Button("Delete card") {
                model.deleteCurrentCard()
                dismiss()
            }
            .buttonStyle(.vj(.danger))
            .padding(.top, 8)
            Text("The card keeps its box. Deleting can be undone for 5 seconds.")
                .font(.vjNote).foregroundStyle(VJ.mute).frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .padding(16).padding(.top, 8)
        .background(VJ.paper)
        .presentationDetents([.large])
    }

    private func save() {
        if model.editCard(card.id, native: native, dutch: dutch) { dismiss() }
    }
}
