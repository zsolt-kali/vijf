import SwiftUI
import VijfKit

@main
struct VijfWatchApp: App {
    @State private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack { BoxListView() }
                .environment(model)
        }
    }
}

/// Pick a deck and box to study. Only boxes with cards are listed.
struct BoxListView: View {
    @Environment(WatchModel.self) private var model
    static let names = ["New", "Shaky", "Getting there", "Nearly", "Learned"]

    var body: some View {
        let boxes = model.boxes
        Group {
            if boxes.isEmpty {
                Text("Open vijf on your iPhone to send your decks to the watch.")
                    .font(.footnote).foregroundStyle(VJ.mute).multilineTextAlignment(.center).padding()
            } else {
                List(boxes) { item in
                    NavigationLink {
                        WatchStudyView()
                            .onAppear { model.startStudy(deck: item.deck.id, box: item.box) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.deck.name).font(.system(size: 15, weight: .bold))
                                Text("Box \(item.box) · \(Self.names[item.box - 1])".uppercased())
                                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(VJ.mute)
                            }
                            Spacer()
                            Text("\(item.count)").font(.system(size: 17, weight: .bold, design: .monospaced))
                        }
                    }
                    .listRowBackground(VJ.card)
                }
            }
        }
        .navigationTitle("Study")
    }
}
