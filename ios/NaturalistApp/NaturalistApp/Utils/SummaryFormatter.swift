import Foundation

enum SummaryFormatter {
    private static let fallbackText = "Resumo indisponível."

    static func cleaned(_ rawSummary: String?) -> String {
        guard let rawSummary, !rawSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallbackText
        }

        let patterns: [(String, String)] = [
            ("\\r\\n?", "\n"),
            ("(?m)^#{1,6}\\s*", ""),
            ("\\[([^\\]]+)\\]\\(([^\\)]+)\\)", "$1"),
            ("(?m)^\\s*[-*+]\\s+", ""),
            ("[*_`~]", ""),
            ("(?m)^\\s*>\\s?", ""),
            ("\\n{3,}", "\n\n")
        ]

        let cleaned = patterns.reduce(rawSummary) { partial, pattern in
            partial.replacingOccurrences(
                of: pattern.0,
                with: pattern.1,
                options: .regularExpression
            )
        }
        .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? fallbackText : cleaned
    }
}
