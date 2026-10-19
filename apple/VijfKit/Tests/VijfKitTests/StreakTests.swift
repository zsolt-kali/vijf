// SPEC.md → Days in a row
import Foundation
import Testing
@testable import VijfKit

@Suite struct StreakTests {
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Europe/Amsterdam")!; return c }
    /// Noon on a day in October 2026 (the 19th is a Monday).
    func oct(_ day: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 12))! }
    func keys(_ days: [Int]) -> [String] { days.map { Streak.key(oct($0), calendar: cal) } }

    @Test func countsDoneDaysBackFromToday() {
        #expect(Streak.count(doneDays: keys([22, 23, 24, 25]), today: oct(25), calendar: cal) == 4)
        // today not done yet doesn't break it
        #expect(Streak.count(doneDays: keys([22, 23, 24]), today: oct(25), calendar: cal) == 3)
        #expect(Streak.count(doneDays: [], today: oct(25), calendar: cal) == 0)
    }

    @Test func oneMissedDayPerWeekIsLetOff() {
        // week of Mon 19 Oct: 21 missed, the rest done
        #expect(Streak.count(doneDays: keys([19, 20, 22, 23, 24]), today: oct(24), calendar: cal) == 5)
        // a second miss in the same week ends it: 23 is let off, 21 isn't
        #expect(Streak.count(doneDays: keys([19, 22, 24]), today: oct(24), calendar: cal) == 2)
        #expect(Streak.count(doneDays: keys([19, 24]), today: oct(24), calendar: cal) == 1)
        // misses in two different weeks are each let off: Sun 18 and Tue 20
        #expect(Streak.count(doneDays: keys([16, 17, 19, 21]), today: oct(21), calendar: cal) == 4)
    }

    @Test func thisWeekFromMondayToSunday() {
        let w = Streak.week(doneDays: keys([19, 20, 22]), today: oct(23), calendar: cal)
        #expect(w == [.done, .done, .missed, .done, .today, .ahead, .ahead])
        #expect(Streak.week(doneDays: keys([23]), today: oct(23), calendar: cal)[4] == .done)
    }

    @Test func aDayIsDoneWhenNothingIsDueInAnyDeck() {
        var l = Library(cards: [Card(id: 1, deckId: 1, native: "a", dutch: "a", createdAt: 0)], nextId: 2,
                        decks: [Deck(id: 1, name: "Start", createdAt: 0)], nextDeckId: 2)
        var added = l.markDoneIfClear(now: oct(23), calendar: cal)
        #expect(!added)                                                // a card is due
        #expect(l.streakNote(now: oct(23), calendar: cal) == "Finish today to start a streak")
        l.answer(1, known: true, now: Int64(oct(23).timeIntervalSince1970 * 1000))
        added = l.markDoneIfClear(now: oct(23), calendar: cal)
        #expect(added)
        #expect(l.doneDays == ["2026-10-23"])
        added = l.markDoneIfClear(now: oct(23), calendar: cal)
        #expect(!added)                                                // once
        let today = l.answeredToday(dayStart: Day.start(of: oct(23), calendar: cal))
        #expect(today.cards == 1 && today.movedUp == 1)
        #expect(l.streakNote(now: oct(23), calendar: cal) == "Done for today")   // box 2: due on the 25th
        #expect(l.dueTomorrow(now: oct(24), calendar: cal) == 1)
        added = l.markDoneIfClear(now: oct(24), calendar: cal)        // nothing due on the 24th either
        #expect(added)
        #expect(l.streakNote(now: oct(24), calendar: cal) == "Done for today · Tomorrow 1 card")
        var empty = Library()
        added = empty.markDoneIfClear(now: oct(23), calendar: cal)
        #expect(!added && empty.doneDays.isEmpty)                      // no cards, no day
    }

    @Test func doneDaysAreSavedAndOldDataHasNone() throws {
        let l = Library(doneDays: ["2026-10-22", "2026-10-23"])
        #expect(try Backup.decode(Backup.encode(l)).doneDays == ["2026-10-22", "2026-10-23"])
        #expect(try Backup.decode(#"{"cards":[]}"#).doneDays == [])
        #expect(try Backup.decode(#"{"cards":[],"doneDays":["2026-10-23","x",3,"2026-10-23"]}"#).doneDays == ["2026-10-23"])
    }

    @Test func phoneAndWatchKeepTheDaysDoneOnEither() {
        let phone = Library(doneDays: ["2026-10-21"]), watch = Library(doneDays: ["2026-10-22"])
        #expect(Sync.merge(phone: phone, into: watch).doneDays == ["2026-10-21", "2026-10-22"])
        var p = phone
        let info = Sync.userInfo(for: [], doneDays: watch.doneDays)
        Sync.addDoneDays(Sync.doneDays(fromUserInfo: info), to: &p)
        #expect(p.doneDays == ["2026-10-21", "2026-10-22"])
    }
}
