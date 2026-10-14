import Foundation
@testable import VijfKit

/// Local midnight `n` days from today (negative: in the past), as the app counts days.
func midnight(_ n: Int = 0) -> Int64 {
    Day.start(of: Calendar.current.date(byAdding: .day, value: n, to: Date())!)
}

/// Around noon `n` days from today: a time to answer a card on that day.
func noon(_ n: Int = 0) -> Int64 { midnight(n) + 12 * 3_600_000 }
