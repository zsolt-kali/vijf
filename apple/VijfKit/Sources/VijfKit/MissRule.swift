/// What "Not yet" does to a card in boxes 2–5 (SPEC.md → Leitner rules). A setting: on the web per
/// browser; on Apple it lives on the iPhone, which sends it to the watch with the library.
public enum MissRule: String, Codable, CaseIterable, Sendable {
    /// One box down: the default.
    case oneDown = "down"
    /// Back to box 1, as in classic Leitner.
    case backToBoxOne = "box1"

    /// The box a card in `box` goes to after "Not yet". Box 1 stays box 1.
    public func boxAfterMiss(_ box: Int) -> Int {
        switch self {
        case .oneDown: max(box - 1, 1)
        case .backToBoxOne: 1
        }
    }
}
