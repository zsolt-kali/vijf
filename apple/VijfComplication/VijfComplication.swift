import SwiftUI
import WidgetKit

/// The watch-face complication: the vijf mark, which opens the app when tapped.
/// It shows no data, so it needs no data sharing with the app and never has to refresh.
@main
struct VijfComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "nl.vijf.launcher", provider: LauncherProvider()) { _ in
            LauncherView()
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("vijf")
        .description("Open vijf to study.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}

struct LauncherEntry: TimelineEntry {
    let date: Date
}

/// One entry that never changes.
struct LauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> LauncherEntry { LauncherEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> Void) {
        completion(LauncherEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> Void) {
        completion(Timeline(entries: [LauncherEntry(date: .now)], policy: .never))
    }
}

struct LauncherView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Text("v")
                    .font(.system(size: 26, weight: .heavy))
                    .offset(y: -2)
                    .widgetAccentable()
            }
            .accessibilityLabel("vijf")
        case .accessoryCorner:
            Text("v")
                .font(.system(size: 22, weight: .heavy))
                .widgetAccentable()
                .widgetLabel("vijf")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 0) {
                Text("vijf").font(.system(size: 17, weight: .heavy)).widgetAccentable()
                Text("Study Dutch").font(.system(size: 13))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            Text("vijf")
        }
    }
}
