import Foundation

/// "Several at once" on the Add screen (SPEC.md → Bulk import format): one card per line,
/// your language first, then Dutch, separated by `=`, `|`, tab or `;`, or else a comma. A line
/// with both `=` and `|` carries example sentences: `word | sentence = woord | zin`, where `=`
/// separates the languages and `|` a word from its sentence (either sentence optional).
public enum BulkImport {
    public struct Entry: Equatable, Sendable {
        public let native: String
        public let dutch: String
        public let nativeExample: String?
        public let dutchExample: String?
    }

    public static func entries(from text: String) -> [Entry] {
        var result: [Entry] = []
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            if line.contains("="), line.contains("|"), let eq = line.firstIndex(of: "=") {
                let (n, ns) = side(String(line[..<eq]))
                let (d, ds) = side(String(line[line.index(after: eq)...]))
                guard !n.isEmpty, !d.isEmpty else { continue }
                result.append(Entry(native: n, dutch: d, nativeExample: ns, dutchExample: ds))
                continue
            }
            var parts = line.split(separator: /\s*[=|\t;]\s*/, omittingEmptySubsequences: false)
            if parts.count < 2 { parts = line.split(separator: /\s*,\s*/, omittingEmptySubsequences: false) }
            guard parts.count >= 2 else { continue }
            let native = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let dutch = String(parts[1]).trimmingCharacters(in: .whitespaces)
            guard !native.isEmpty, !dutch.isEmpty else { continue }
            result.append(Entry(native: native, dutch: dutch, nativeExample: nil, dutchExample: nil))
        }
        return result
    }

    /// One side of a sentence line: the word, and the sentence after its first `|` (anything
    /// after a second `|` is ignored).
    private static func side(_ s: String) -> (String, String?) {
        let parts = s.split(separator: "|", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        return (parts[0], parts.count > 1 ? Card.sentence(parts[1]) : nil)
    }

    /// The words alone, as before example sentences.
    public static func pairs(from text: String) -> [(native: String, dutch: String)] {
        entries(from: text).map { ($0.native, $0.dutch) }
    }
}

/// Where a card's word appears in its example sentence, ignoring case and accents, so it can be
/// underlined. Nil when it doesn't appear as written.
public enum ExampleMark {
    public static func range(of word: String, in sentence: String) -> Range<String.Index>? {
        let w = word.trimmingCharacters(in: .whitespaces)
        guard !w.isEmpty else { return nil }
        return sentence.range(of: w, options: [.caseInsensitive, .diacriticInsensitive])
    }
}
