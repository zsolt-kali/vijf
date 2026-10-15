import Foundation

/// The version line on the iPhone's Backup screen and the watch's deck list: the commit the app
/// was built from and its date, as the web app shows it. `scripts/stamp_version.sh` writes the
/// two Info.plist keys on every build.
public enum AppVersion {
    /// "Version 3116643 · 15 Oct 2026"; "Version dev" when the keys are missing.
    public static func text(info: [String: Any]? = Bundle.main.infoDictionary) -> String {
        guard let commit = info?["VijfCommit"] as? String, !commit.isEmpty else { return "Version dev" }
        guard let raw = info?["VijfCommitDate"] as? String, let date = parse.date(from: raw) else {
            return "Version \(commit)"
        }
        return "Version \(commit) · \(show.string(from: date))"
    }

    private static let parse = formatter("yyyy-MM-dd")
    private static let show = formatter("d MMM yyyy")

    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = format
        return f
    }
}
