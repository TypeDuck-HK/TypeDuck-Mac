import Foundation
import SQLite3

public struct Emoji: Hashable {
        public enum Category: Int, Hashable, CaseIterable {
                case smileysAndPeople = 1
                case animalsAndNature = 2
                case foodAndDrink = 3
                case activity = 4
                case travelAndPlaces = 5
                case objects = 6
                case symbols = 7
                case flags = 8
        }
        public let category: Category
        public let text: String
        public let cantonese: String
        public let romanization: String
}

extension Engine {

        /// Fetch Emoji from database
        /// - Parameter category: Fetch all Emoji if category is nil
        /// - Returns: An Array of Emoji
        public static func fetchEmoji(category: Emoji.Category? = nil) -> [Emoji] {
                var emojis: [Emoji] = []
                let tailQueryText: String = {
                        guard let categoryCode = category?.rawValue else { return "" }
                        return " WHERE category = \(categoryCode)"
                }()
                let query = "SELECT category, codepoint, cantonese, romanization FROM symboltable\(tailQueryText);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(Engine.database, query, -1, &statement, nil) == SQLITE_OK else { return emojis }
                while sqlite3_step(statement) == SQLITE_ROW {
                        let categoryCode: Int = Int(sqlite3_column_int64(statement, 0))
                        let codepoint: String = String(cString: sqlite3_column_text(statement, 1))
                        let cantonese: String = String(cString: sqlite3_column_text(statement, 2))
                        let romanization: String = String(cString: sqlite3_column_text(statement, 3))
                        if let category = Emoji.Category(rawValue: categoryCode), let text = generateSymbol(from: codepoint) {
                                let emoji = Emoji(category: category, text: text, cantonese: cantonese, romanization: romanization)
                                emojis.append(emoji)
                        }
                }
                return emojis
        }

        public static func searchSymbols(text: String, segmentation: Segmentation) -> [Candidate] {
                let regular: [Candidate] = match(text: text, input: text)
                let textCount = text.count
                let schemes = segmentation.filter({ $0.length == textCount })
                guard schemes.isNotEmpty else { return regular }
                let matches = schemes.map({ scheme -> [Candidate] in
                        let pingText = scheme.map(\.origin).joined()
                        return match(text: pingText, input: text)
                })
                let symbols: [Candidate] = regular + matches.flatMap({ $0 })
                return symbols
        }

        private static func match(text: String, input: String) -> [Candidate] {
                var candidates: [Candidate] = []
                let command: String = "SELECT category, codepoint, cantonese, romanization FROM symboltable WHERE ping = \(text.hash);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(Engine.database, command, -1, &statement, nil) == SQLITE_OK else { return candidates }
                while sqlite3_step(statement) == SQLITE_ROW {
                        let categoryCode: Int = Int(sqlite3_column_int64(statement, 0))
                        let codepoint: String = String(cString: sqlite3_column_text(statement, 1))
                        let cantonese: String = String(cString: sqlite3_column_text(statement, 2))
                        let romanization: String = String(cString: sqlite3_column_text(statement, 3))
                        if let symbolText = generateSymbol(from: codepoint) {
                                let isEmoji: Bool = (categoryCode > 0) && (categoryCode < 9)
                                let instance = Candidate(symbol: symbolText, cantonese: cantonese, romanization: romanization, input: input, isEmoji: isEmoji)
                                candidates.append(instance)
                        }
                }
                return candidates
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
