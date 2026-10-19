import Foundation

/// Days in a row (SPEC.md → Days in a row). A day is done when nothing is due in any deck; the
/// library records those days in `doneDays` as local "YYYY-MM-DD". The count runs back from
/// today; today not done yet doesn't break it, and one missed day per calendar week (Monday to
/// Sunday) is let off. Mirrors `streak()` in web/index.html.
public enum Streak {
    /// One square of this week's row.
    public enum Mark: Equatable, Sendable { case done, today, missed, ahead }

    /// The local day `date` falls on, as "YYYY-MM-DD".
    public static func key(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func isKey(_ s: String) -> Bool {
        s.count == 10 && s.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil
    }

    public static func count(doneDays: [String], today: Date = Date(), calendar: Calendar = .current) -> Int {
        let done = Set(doneDays)
        guard let earliest = doneDays.min() else { return 0 }
        var day = calendar.startOfDay(for: today)
        if !done.contains(key(day, calendar: calendar)) { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        var count = 0
        var forgiven = Set<String>()
        while key(day, calendar: calendar) >= earliest {
            if done.contains(key(day, calendar: calendar)) {
                count += 1
            } else {
                let week = key(monday(of: day, calendar: calendar), calendar: calendar)
                if forgiven.contains(week) { break }
                forgiven.insert(week)
            }
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    /// This week, Monday to Sunday.
    public static func week(doneDays: [String], today: Date = Date(), calendar: Calendar = .current) -> [Mark] {
        let done = Set(doneDays)
        let start = monday(of: today, calendar: calendar)
        let todayKey = key(today, calendar: calendar)
        return (0..<7).map { i in
            let k = key(calendar.date(byAdding: .day, value: i, to: start)!, calendar: calendar)
            if done.contains(k) { return .done }
            if k == todayKey { return .today }
            return k < todayKey ? .missed : .ahead
        }
    }

    static func monday(of date: Date, calendar: Calendar) -> Date {
        let day = calendar.startOfDay(for: date)
        let fromMonday = (calendar.component(.weekday, from: day) + 5) % 7
        return calendar.date(byAdding: .day, value: -fromMonday, to: day)!
    }
}

extension Library {
    /// Every card due on the day starting at `dayStart`, in all decks.
    public func dueTotal(dayStart: Int64) -> Int {
        cards.filter { $0.isDue(dayStart: dayStart) }.count
    }

    /// Records today as done when there are cards and none is due. Returns whether it added it.
    @discardableResult
    public mutating func markDoneIfClear(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        let today = Streak.key(now, calendar: calendar)
        guard !cards.isEmpty, !doneDays.contains(today),
              dueTotal(dayStart: Day.start(of: now, calendar: calendar)) == 0 else { return false }
        doneDays = (doneDays + [today]).sorted()
        return true
    }

    public func isDone(on now: Date = Date(), calendar: Calendar = .current) -> Bool {
        doneDays.contains(Streak.key(now, calendar: calendar))
    }

    /// For the Done for today screen: cards answered today, and of those moved up ("I know it").
    public func answeredToday(dayStart: Int64) -> (cards: Int, movedUp: Int) {
        (cards.filter { ($0.seenAt ?? .min) >= dayStart }.count,
         cards.filter { ($0.reviewedAt ?? .min) >= dayStart }.count)
    }

    /// Cards that will be due tomorrow.
    public func dueTomorrow(now: Date = Date(), calendar: Calendar = .current) -> Int {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        return dueTotal(dayStart: Day.start(of: tomorrow, calendar: calendar))
    }

    /// The deck list's second streak line: "Finish today to make it 13", "Finish today to start
    /// a streak", or "Done for today · Tomorrow 18 cards".
    public func streakNote(now: Date = Date(), calendar: Calendar = .current) -> String {
        if isDone(on: now, calendar: calendar) {
            let n = dueTomorrow(now: now, calendar: calendar)
            return n > 0 ? "Done for today · Tomorrow \(n) \(n == 1 ? "card" : "cards")" : "Done for today"
        }
        let streak = Streak.count(doneDays: doneDays, today: now, calendar: calendar)
        return streak > 0 ? "Finish today to make it \(streak + 1)" : "Finish today to start a streak"
    }
}
