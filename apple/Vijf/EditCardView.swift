import SwiftUI
import VijfKit

/// Fixing or deleting the card being studied or browsed, or one found by search (SPEC.md →
/// Editing a card, Search, Browsing a deck).
struct EditCardView: View {
    enum Origin { case study, browse, search }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let card: Card
    let origin: Origin
    @State private var native: String
    @State private var dutch: String

    init(card: Card, origin: Origin) {
        self.card = card
        self.origin = origin
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
                switch origin {
                case .study: model.deleteCurrentCard()
                case .browse: model.deleteBrowsedCard()
                case .search: model.deleteCard(card.id)
                }
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
