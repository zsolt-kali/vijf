import SwiftUI
import VijfKit
import WidgetKit

/// The watch-face complication: the vijf mark from the app icon, which opens the app when tapped.
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
                BarMark().padding(11)
            }
            .accessibilityLabel("vijf")
        case .accessoryCorner:
            BarMark()
                .padding(3)
                .widgetLabel("vijf")
                .accessibilityLabel("vijf")
        case .accessoryRectangular:
            HStack(spacing: 8) {
                BarMark().frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 0) {
                    Text("vijf").font(.system(size: 17, weight: .heavy)).widgetAccentable()
                    Text("Study Dutch").font(.system(size: 13))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        default:
            Text("vijf")
        }
    }
}

/// The app icon's mark: five bars narrowing downward, one per Leitner box, with the top bar
/// (box 5, learned) highlighted. Proportions are taken from the icon (bars 100/85/71/56/42% wide).
///
/// Tinted faces: the top bar takes the face's accent colour, the others stay white.
/// Full-colour faces: the top bar is vijf yellow and the others light, as in the icon.
struct BarMark: View {
    @Environment(\.widgetRenderingMode) private var mode
    static let widths: [CGFloat] = [1.0, 0.854, 0.707, 0.561, 0.415]

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let barHeight = side * 0.1585
            let gap = side * 0.0488
            VStack(spacing: gap) {
                Rectangle()
                    .fill(mode == .fullColor ? Color(hex: Tokens.signal.dark) : .primary)
                    .frame(width: side * Self.widths[0], height: barHeight)
                    .widgetAccentable()
                ForEach(Self.widths.dropFirst(), id: \.self) { w in
                    Rectangle()
                        .fill(mode == .fullColor ? Color(hex: Tokens.ink.dark) : Color.primary.opacity(mode == .vibrant ? 0.6 : 1))
                        .frame(width: side * w, height: barHeight)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

private extension Color {
    init(hex: String) {
        let v = UInt32(hex.dropFirst(), radix: 16) ?? 0
        self.init(red: Double((v >> 16) & 0xff) / 255, green: Double((v >> 8) & 0xff) / 255, blue: Double(v & 0xff) / 255)
    }
}
