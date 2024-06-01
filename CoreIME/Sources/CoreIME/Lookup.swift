import Foundation
import SQLite3

extension Engine {
        public static func embedNotations(for origin: Candidate) -> Candidate {
                let text = origin.text
                let romanization = origin.romanization
                if let notation = fetchNotation(word: text, romanization: romanization) {
                        return Candidate(text: text, romanization: romanization, input: origin.input, mark: origin.mark, notation: notation)
                } else {
                        let textCount = text.count
                        switch textCount {
                        case 0, 1:
                                return origin
                        case 3:
                                let syllables = romanization.split(separator: Character.space).map({ String($0) })
                                let subNotations: [Notation] = {
                                        let leadingCharacters = text.prefix(2)
                                        let trailingCharacters = text.suffix(1)
                                        let leadingRomanization = syllables.prefix(2).joined(separator: String.space)
                                        let trailingRomanization = syllables.suffix(1).joined(separator: String.space)
                                        let leadingNotation = fetchNotation(word: leadingCharacters, romanization: leadingRomanization)
                                        let trailingNotation = fetchNotation(word: trailingCharacters, romanization: trailingRomanization)
                                        return [leadingNotation, trailingNotation].compactMap({ $0 }).uniqued()
                                }()
                                guard subNotations.count < 2 else { return Candidate(text: text, romanization: romanization, input: origin.input, mark: origin.mark, subNotations: subNotations) }
                                let subNotationsAlt: [Notation] = {
                                        let leadingCharacters = text.prefix(1)
                                        let trailingCharacters = text.suffix(2)
                                        let leadingRomanization = syllables.prefix(1).joined(separator: String.space)
                                        let trailingRomanization = syllables.suffix(2).joined(separator: String.space)
                                        let leadingNotation = fetchNotation(word: leadingCharacters, romanization: leadingRomanization)
                                        let trailingNotation = fetchNotation(word: trailingCharacters, romanization: trailingRomanization)
                                        return [leadingNotation, trailingNotation].compactMap({ $0 }).uniqued()
                                }()
                                guard subNotationsAlt.count < 2 else { return Candidate(text: text, romanization: romanization, input: origin.input, mark: origin.mark, subNotations: subNotationsAlt) }
                                let anotherSubNotations: [Notation] = {
                                        let characters = text.map({ String($0) })
                                        guard characters.count == syllables.count else { return [] }
                                        var notations: [Notation] = []
                                        for index in 0..<characters.count {
                                                if let notation = fetchNotation(word: characters[index], romanization: syllables[index]) {
                                                        notations.append(notation)
                                                }
                                        }
                                        return notations.uniqued()
                                }()
                                return Candidate(text: text, romanization: romanization, input: origin.input, mark: origin.mark, subNotations: anotherSubNotations)
                        case 5:
                                let syllables = romanization.split(separator: Character.space).map({ String($0) })
                                let subNotations: [Notation] = {
                                        let leadingCharacters = text.prefix(2)
                                        let trailingCharacters = text.suffix(3)
                                        let leadingRomanization = syllables.prefix(2).joined(separator: String.space)
                                        let trailingRomanization = syllables.suffix(3).joined(separator: String.space)
                                        let leadingNotation = fetchNotation(word: leadingCharacters, romanization: leadingRomanization)
                                        let trailingNotation = fetchNotation(word: trailingCharacters, romanization: trailingRomanization)
                                        return [leadingNotation, trailingNotation].compactMap({ $0 }).uniqued()
                                }()
                                guard subNotations.isEmpty else { return Candidate(text: text, romanization: romanization, input: origin.input, mark: origin.mark, subNotations: subNotations) }
                                let subNotationsAlt: [Notation] = {
                                        let leadingCharacters = text.prefix(3)
                                        let trailingCharacters = text.suffix(2)
                                        let leadingRomanization = syllables.prefix(3).joined(separator: String.space)
                                        let trailingRomanization = syllables.suffix(2).joined(separator: String.space)
                                        let leadingNotation = fetchNotation(word: leadingCharacters, romanization: leadingRomanization)
                                        let trailingNotation = fetchNotation(word: trailingCharacters, romanization: trailingRomanization)
                                        return [leadingNotation, trailingNotation].compactMap({ $0 }).uniqued()
                                }()
                                return Candidate(text: text, romanization: romanization, input: origin.input, mark: origin.mark, subNotations: subNotationsAlt)
                        case 6:
                                let syllables = romanization.split(separator: Character.space).map({ String($0) })
                                let subNotations: [Notation] = {
                                        let leadingCharacters = text.prefix(3)
                                        let trailingCharacters = text.suffix(3)
                                        let leadingRomanization = syllables.prefix(3).joined(separator: String.space)
                                        let trailingRomanization = syllables.suffix(3).joined(separator: String.space)
                                        let leadingNotation = fetchNotation(word: leadingCharacters, romanization: leadingRomanization)
                                        let trailingNotation = fetchNotation(word: trailingCharacters, romanization: trailingRomanization)
                                        return [leadingNotation, trailingNotation].compactMap({ $0 }).uniqued()
                                }()
                                guard subNotations.isEmpty else { return Candidate(text: text, romanization: romanization, input: origin.input, mark: origin.mark, subNotations: subNotations) }
                                let subNotationsAlt: [Notation] = {
                                        let leadingCharacters = text.prefix(2)
                                        let mediumCharacters = text.dropFirst(2).prefix(2)
                                        let trailingCharacters = text.suffix(2)
                                        let leadingRomanization = syllables.prefix(2).joined(separator: String.space)
                                        let mediumRomanization = syllables.dropFirst(2).prefix(2).joined(separator: String.space)
                                        let trailingRomanization = syllables.suffix(2).joined(separator: String.space)
                                        let leadingNotation = fetchNotation(word: leadingCharacters, romanization: leadingRomanization)
                                        let mediumNotation = fetchNotation(word: mediumCharacters, romanization: mediumRomanization)
                                        let trailingNotation = fetchNotation(word: trailingCharacters, romanization: trailingRomanization)
                                        return [leadingNotation, mediumNotation, trailingNotation].compactMap({ $0 }).uniqued()
                                }()
                                return Candidate(text: text, romanization: romanization, input: origin.input, mark: origin.mark, subNotations: subNotationsAlt)
                        default:
                                let leadingCount = textCount / 2
                                let trailingCount = textCount - leadingCount
                                let leadingText = text.prefix(leadingCount)
                                let trailingText = text.suffix(trailingCount)
                                let syllables = romanization.split(separator: Character.space)
                                let leadingRomanization = syllables.prefix(leadingCount).joined(separator: String.space)
                                let trailingRomanization = syllables.suffix(trailingCount).joined(separator: String.space)
                                let leadingNotation = fetchNotation(word: leadingText, romanization: leadingRomanization)
                                let trailingNotation = fetchNotation(word: trailingText, romanization: trailingRomanization)
                                let subNotations: [Notation] = [leadingNotation, trailingNotation].compactMap({ $0 }).uniqued()
                                return Candidate(text: text, romanization: romanization, input: origin.input, mark: origin.mark, subNotations: subNotations)
                        }
                }
        }
        public static func fetchNotation<T: StringProtocol>(word: T, romanization: String) -> Notation? {
                let ping: Int = romanization.removedSpacesTones().hash
                let command: String = "SELECT word, romanization, frequency, altfrequency, pronunciationorder, sandhi, literarycolloquial, partofspeech, register, label, normalized, written, vernacular, collocation, english, urdu, nepali, hindi, indonesian FROM lexicontable WHERE ping = \(ping) AND word = '\(word)' AND romanization = '\(romanization)' LIMIT 1;"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return nil }
                guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
                let word: String = String(cString: sqlite3_column_text(statement, 0))
                let romanization: String = String(cString: sqlite3_column_text(statement, 1))
                let frequency: Int = Int(sqlite3_column_int64(statement, 2))
                let altFrequency: Int = Int(sqlite3_column_int64(statement, 3))
                let pronunciationOrder: Int = Int(sqlite3_column_int64(statement, 4))
                let sandhi: Int = Int(sqlite3_column_int64(statement, 5))
                let literaryColloquial: String = String(cString: sqlite3_column_text(statement, 6))
                let partOfSpeech: String = String(cString: sqlite3_column_text(statement, 7))
                let register: String = String(cString: sqlite3_column_text(statement, 8))
                let label: String = String(cString: sqlite3_column_text(statement, 9))
                let normalized: String = String(cString: sqlite3_column_text(statement, 10))
                let written: String = String(cString: sqlite3_column_text(statement, 11))
                let vernacular: String = String(cString: sqlite3_column_text(statement, 12))
                let collocation: String = String(cString: sqlite3_column_text(statement, 13))
                let english: String = String(cString: sqlite3_column_text(statement, 14))
                let urdu: String = String(cString: sqlite3_column_text(statement, 15))
                let nepali: String = String(cString: sqlite3_column_text(statement, 16))
                let hindi: String = String(cString: sqlite3_column_text(statement, 17))
                let indonesian: String = String(cString: sqlite3_column_text(statement, 18))
                let isSandhi: Bool = sandhi == 1
                let notation: Notation = Notation(word: word, jyutping: romanization, frequency: frequency, altFrequency: altFrequency, pronunciationOrder: pronunciationOrder, isSandhi: isSandhi, literaryColloquial: literaryColloquial, partOfSpeech: partOfSpeech, register: register, label: label, normalized: normalized, written: written, vernacular: vernacular, collocation: collocation, english: english, urdu: urdu, nepali: nepali, hindi: hindi, indonesian: indonesian)
                return notation
        }
}

extension Engine {

        /// Reverse Lookup.
        /// - Parameters:
        ///   - text: Cantonese word text.
        ///   - input: User input for this word.
        ///   - mark: Formatted user input for pre-edit display.
        /// - Returns: Candidates.
        static func reveresLookup(text: String, input: String, mark: String? = nil) -> [Candidate] {
                let romanizations: [String] = Engine.lookup(text)
                let candidates = romanizations.map { romanization -> Candidate in
                        let notation: Notation? = fetchNotation(word: text, romanization: romanization)
                        return Candidate(text: text, lexiconText: text, romanization: romanization, input: input, mark: mark ?? input, notation: notation)
                }
                return candidates
        }

        /// Search Romanization for word
        /// - Parameter text: word
        /// - Returns: Array of Romanization matched the input word
        static func lookup(_ text: String) -> [String] {
                guard !text.isEmpty else { return [] }
                let matched = match(for: text)
                guard matched.isEmpty else { return matched }
                guard text.count != 1 else { return [] }
                var chars: String = text
                var fetches: [String] = []
                while !chars.isEmpty {
                        let leading = fetchLeading(for: chars)
                        if let romanization: String = leading.romanization {
                                fetches.append(romanization)
                                let length: Int = max(1, leading.charCount)
                                chars = String(chars.dropFirst(length))
                        } else {
                                fetches.append("?")
                                chars = String(chars.dropFirst())
                        }
                }
                guard !fetches.isEmpty else { return [] }
                let suggestion: String = fetches.joined(separator: " ")
                return [suggestion]
        }

        private static func fetchLeading(for word: String) -> (romanization: String?, charCount: Int) {
                var chars: String = word
                var romanization: String? = nil
                var matchedCount: Int = 0
                while romanization == nil && !chars.isEmpty {
                        romanization = match(for: chars).first
                        matchedCount = chars.count
                        chars = String(chars.dropLast())
                }
                guard let matched: String = romanization else {
                        return (nil, 0)
                }
                return (matched, matchedCount)
        }

        private static func match(for text: String) -> [String] {
                var romanizations: [String] = []
                let command: String = "SELECT romanization FROM lexicontable WHERE word = '\(text)';"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(Engine.database, command, -1, &statement, nil) == SQLITE_OK else { return romanizations }
                while sqlite3_step(statement) == SQLITE_ROW {
                        let romanization: String = String(cString: sqlite3_column_text(statement, 0))
                        romanizations.append(romanization)
                }
                return romanizations
        }
}
