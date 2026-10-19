import SwiftUI
import VijfKit

/// The deck list's streak line (SPEC.md → Days in a row): "12 DAYS IN A ROW", what to do next,
/// and this week's squares.
struct StreakLine: View {
    let library: Library

    var body: some View {
        let count = Streak.count(doneDays: library.doneDays)
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                (Text("\(count)").bold().foregroundColor(library.isDone() ? VJ.deep : VJ.ink)
                 + Text(count == 1 ? " DAY IN A ROW" : " DAYS IN A ROW").foregroundColor(VJ.ink))
                    .font(.vjMono(11)).tracking(1.1)
                Eyebrow(library.streakNote())
            }
            Spacer()
            WeekSquares(marks: Streak.week(doneDays: library.doneDays), size: 12)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Monday to Sunday: `deep` = done, `ink` outline = today, `line` outline = missed or ahead.
struct WeekSquares: View {
    let marks: [Streak.Mark]
    let size: CGFloat
    var stretch = false

    var body: some View {
        HStack(spacing: stretch ? 4 : 3) {
            ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                Group {
                    switch mark {
                    case .done: Rectangle().fill(VJ.deep)
                    case .today: Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke)
                    case .missed, .ahead: Rectangle().strokeBorder(VJ.line, lineWidth: VJ.stroke)
                    }
                }
                .frame(width: stretch ? nil : size, height: size)
                .frame(maxWidth: stretch ? .infinity : nil)
            }
        }
        .accessibilityLabel("This week: \(marks.filter { $0 == .done }.count) of 7 days done")
    }
}

/// Shown instead of the summary when a session ends and nothing is due in any deck.
struct DoneTodayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let library = model.library
        let today = library.answeredToday(dayStart: Day.start())
        let tomorrow = library.dueTomorrow()
        let count = Streak.count(doneDays: library.doneDays)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Done for today.").font(.system(size: 34, weight: .heavy)).tracking(-1.3).padding(.top, 18)
                Text("Every deck is done. Nothing else is due until tomorrow.").font(.vjBody).foregroundStyle(VJ.mute)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(count)").font(.vjMono(40, weight: .bold)).foregroundStyle(VJ.deep)
                        Text(count == 1 ? "DAY IN A ROW" : "DAYS IN A ROW").font(.vjMono(11)).tracking(1.1).foregroundStyle(VJ.ink)
                    }
                    WeekSquares(marks: Streak.week(doneDays: library.doneDays), size: 16, stretch: true)
                    HStack {
                        ForEach(["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"], id: \.self) { d in
                            Text(d).font(.vjMono(9)).tracking(0.9).foregroundStyle(VJ.mute).frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.vertical, 18).padding(.horizontal, 16)
                .background(VJ.card)
                .overlay(Rectangle().strokeBorder(VJ.ink, lineWidth: VJ.stroke))
                .padding(.top, 10)

                VStack(spacing: 0) {
                    row("Today", "\(today.cards) \(today.cards == 1 ? "card" : "cards") · \(today.movedUp) moved up")
                    row("Tomorrow", "\(tomorrow) \(tomorrow == 1 ? "card" : "cards")")
                }
                .overlay(alignment: .top) { Rectangle().fill(VJ.line).frame(height: VJ.stroke) }

                Button("Back to decks") { model.path = [] }.buttonStyle(.vj(.fill)).padding(.top, 8)
            }
            .padding(16)
        }
        .background(VJ.paper)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.vjBody).foregroundStyle(VJ.ink)
            Spacer()
            Text(value).font(.vjMono(13)).foregroundStyle(VJ.ink)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(VJ.line).frame(height: VJ.stroke) }
    }
}
