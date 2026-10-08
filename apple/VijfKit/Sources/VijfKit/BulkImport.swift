/// "Several at once" on the Add screen (SPEC.md → Bulk import format): one card per line,
/// your language first, then Dutch, separated by `=`, `|`, tab or `;`, or else a comma.
public enum BulkImport {
    public static func pairs(from text: String) -> [(native: String, dutch: String)] {
        var result: [(String, String)] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            var parts = line.split(separator: /\s*[=|\t;]\s*/, omittingEmptySubsequences: false)
            if parts.count < 2 { parts = line.split(separator: /\s*,\s*/, omittingEmptySubsequences: false) }
            guard parts.count >= 2 else { continue }
            let native = parts[0].trimmingCharacters(in: .whitespaces)
            let dutch = parts[1].trimmingCharacters(in: .whitespaces)
            guard !native.isEmpty, !dutch.isEmpty else { continue }
            result.append((native, dutch))
        }
        return result
    }
}

private extension Substring {
    func trimmingCharacters(in set: CharacterSet) -> String {
        String(self).trimmingCharacters(in: set)
    }
}

import Foundation
