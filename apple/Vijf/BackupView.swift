import SwiftUI
import UIKit
import VijfKit

/// Copying the data out and restoring it (SPEC.md → Screens → Backup). The text is the same
/// JSON as the web app's, so a backup moves between the web app and the iPhone app either way.
struct BackupView: View {
    @Environment(AppModel.self) private var model
    @State private var pasted = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your cards live only on this device. Copy this text somewhere safe, or share it. To restore, paste a backup below and tap Restore. This replaces everything.")
                    .font(.vjNote).foregroundStyle(VJ.mute)

                VStack(alignment: .leading, spacing: 5) {
                    Eyebrow("Your data")
                    Text(model.backupText)
                        .font(.vjMono(12))
                        .textSelection(.enabled)
                        .lineLimit(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(VJ.card)
                        .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
                }
                HStack(spacing: 8) {
                    Button("Copy") {
                        UIPasteboard.general.string = model.backupText
                        model.show("Copied")
                    }
                    .buttonStyle(.vj())
                    ShareLink(item: model.backupText) { Text("Share") }.buttonStyle(.vj())
                }

                VStack(alignment: .leading, spacing: 5) {
                    Eyebrow("Paste a backup")
                    TextEditor(text: $pasted)
                        .font(.vjMono(12))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(VJ.card)
                        .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
                }
                .padding(.top, 14)
                Button("Restore") { if model.restore(from: pasted) { pasted = "" } }
                    .buttonStyle(.vj(.fill))
                    .disabled(pasted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
        }
        .background(VJ.paper)
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
    }
}
