import Foundation
import SQLite3

extension Engine {
        static func searchSymbols(text: String, segmentation: Segmentation) -> [Candidate] {
                let regular: [Candidate] = match(text: text, input: text)
                let textCount = text.count
                let schemes = segmentation.filter({ $0.length == textCount })
                guard schemes.isNotEmpty else { return regular }
                let matches = schemes.map({ scheme -> [Candidate] in
                        let pingText = scheme.map(\.origin).joined()
                        return match(text: pingText, input: text)
                })
                return regular + matches.flatMap({ $0 })
        }
        private static func match<T: StringProtocol>(text: T, input: String) -> [Candidate] {
                let command: String = "SELECT category, codepoint, cantonese, romanization FROM symboltable WHERE ping = ?;"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(Engine.database, command, -1, &statement, nil) == SQLITE_OK else { return [] }
                let code = Int64(text.hash)
                guard sqlite3_bind_int64(statement, 1, code) == SQLITE_OK else { return [] }
                var symbols: [SymbolEntry] = []
                while sqlite3_step(statement) == SQLITE_ROW {
                        let categoryCode: Int = Int(sqlite3_column_int64(statement, 0))
                        let codepoint: String = String(cString: sqlite3_column_text(statement, 1))
                        let cantonese: String = String(cString: sqlite3_column_text(statement, 2))
                        let romanization: String = String(cString: sqlite3_column_text(statement, 3))
                        let entry = SymbolEntry(categoryCode: categoryCode, codepoint: codepoint, cantonese: cantonese, romanization: romanization)
                        symbols.append(entry)
                }
                let candidates: [Candidate] = symbols.compactMap({ entry -> Candidate? in
                        let codePointText: String = (entry.categoryCode == 1 || entry.categoryCode == 4) ? (mapSkinTone(entry.codepoint) ?? entry.codepoint) : entry.codepoint
                        guard let symbolText = generateSymbol(from: codePointText) else { return nil }
                        return Candidate(symbol: symbolText, cantonese: entry.cantonese, romanization: entry.romanization, input: input, isEmoji: entry.categoryCode != 9)
                })
                return candidates
        }
        private static func mapSkinTone(_ source: String) -> String? {
                let command: String = "SELECT target FROM emojiskinmapping WHERE source = '\(source)';"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(Engine.database, command, -1, &statement, nil) == SQLITE_OK else { return nil }
                guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
                let target: String = String(cString: sqlite3_column_text(statement, 0))
                return target
        }

        /// Convert code-point-text to symbol text
        /// - Parameter codes: Unicode code points.
        /// - Returns: Symbol text
        private static func generateSymbol(from codes: String) -> String? {
                let blocks = codes.split(separator: ".")
                switch blocks.count {
                case 0:
                        return nil
                case 1:
                        guard let character = character(from: codes) else { return nil }
                        return String(character)
                default:
                        let characters = blocks.map({ character(from: $0) }).compactMap({ $0 })
                        return String(characters)
                }
        }

        /// Create a Character from the given Unicode Code Point String, e.g. 1F600
        private static func character<T: StringProtocol>(from codePoint: T) -> Character? {
                guard let u32 = UInt32(codePoint, radix: 16) else { return nil }
                guard let scalar = Unicode.Scalar(u32) else { return nil }
                return Character(scalar)
        }
}

private struct SymbolEntry: Hashable {
        let categoryCode: Int
        let codepoint: String
        let cantonese: String
        let romanization: String
}
