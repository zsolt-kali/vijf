import SwiftUI
import VijfKit

/// Adding words one at a time or as a list (SPEC.md → Screens → Add, Bulk import format).
struct AddWordsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var deckId: Int
    @State private var native = ""
    @State private var dutch = ""
    @State private var bulk = ""
    @FocusState private var nativeFocused: Bool

    init(deckId: Int) { _deckId = State(initialValue: deckId) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Eyebrow("Deck")
                        Picker("Deck", selection: $deckId) {
                            ForEach(model.library.decks) { Text($0.name).tag($0.id) }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(VJ.card)
                        .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
                    }

                    Text("New word").font(.vjHeading).padding(.top, 14)
                    VJField(label: "Your language", text: $native).focused($nativeFocused)
                    VJField(label: "Dutch", text: $dutch).onSubmit(saveOne)
                    Button("Save to box 1", action: saveOne).buttonStyle(.vj(.fill))

                    Text("Several at once").font(.vjHeading).padding(.top, 20)
                    VStack(alignment: .leading, spacing: 5) {
                        Eyebrow("One per line: your word = Dutch word")
                        TextEditor(text: $bulk)
                            .font(.vjMono(15))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 130)
                            .padding(8)
                            .background(VJ.card)
                            .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
                            .overlay(alignment: .topLeading) {
                                if bulk.isEmpty {
                                    Text("the house = het huis\ntomorrow = morgen").font(.vjMono(15))
                                        .foregroundStyle(VJ.mute).padding(16).allowsHitTesting(false)
                                }
                            }
                    }
                    Button("Import list") { if model.importList(bulk, to: deckId) { bulk = "" } }
                        .buttonStyle(.vj())
                }
                .padding(16)
            }
            .background(VJ.paper)
            .navigationTitle("Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .tint(VJ.ink)
    }

    private func saveOne() {
        if model.addCard(native: native, dutch: dutch, to: deckId) {
            native = ""; dutch = ""; nativeFocused = true
        }
    }
}
