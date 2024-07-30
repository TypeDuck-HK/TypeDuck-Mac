import Foundation
import SQLite3

public struct Engine {

        private static var storageDatabase: OpaquePointer? = nil
        private(set) static var database: OpaquePointer? = nil
        private static var isDatabaseReady: Bool = false

        public static func prepare() {
                Segmentor.prepare()
                let shouldPrepare: Bool = !isDatabaseReady || (database == nil)
                guard shouldPrepare else { return }
                sqlite3_close_v2(storageDatabase)
                sqlite3_close_v2(database)
                guard let path: String = Bundle.module.path(forResource: "imedb", ofType: "sqlite3") else { return }
                guard sqlite3_open_v2(path, &storageDatabase, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return }
                guard sqlite3_open_v2(":memory:", &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else { return }
                let backup = sqlite3_backup_init(database, "main", storageDatabase, "main")
                guard sqlite3_backup_step(backup, -1) == SQLITE_DONE else { return }
                guard sqlite3_backup_finish(backup) == SQLITE_OK else { return }
                sqlite3_close_v2(storageDatabase)
                isDatabaseReady = true
        }


        // MARK: - Suggestion

        /// Suggestion
        /// - Parameters:
        ///   - text: User input text.
        ///   - segmentation: Segmentation of user input text.
        ///   - needsSymbols: Needs Emoji/Symbol Candidates.
        ///   - asap: Should be fast, shouldn't go deep.
        /// - Returns: Candidates
        public static func suggest(text: String, segmentation: Segmentation, needsSymbols: Bool, asap: Bool) -> [Candidate] {
                switch text.count {
                case 0:
                        return []
                case 1:
                        switch text {
                        case "a":
                                return match(text: text, input: text) + match(text: "aa", input: text) + shortcut(text: text)
                        case "o", "m", "e":
                                return match(text: text, input: text) + shortcut(text: text)
                        default:
                                return shortcut(text: text)
                        }
                default:
                        guard asap else { return dispatch(text: text, segmentation: segmentation, needsSymbols: needsSymbols) }
                        guard segmentation.maxSchemeLength > 0 else { return processVerbatim(text: text) }
                        let candidates = query(text: text, segmentation: segmentation, needsSymbols: needsSymbols)
                        return candidates.isEmpty ? processVerbatim(text: text) : candidates
                }
        }

        private static func dispatch(text: String, segmentation: Segmentation, needsSymbols: Bool) -> [Candidate] {
                switch (text.hasSeparators, text.hasTones) {
                case (true, true):
                        let syllable = text.removedSeparatorsTones()
                        return match(text: syllable, input: text).filter({ text.hasPrefix($0.romanization) })
                case (false, true):
                        let textTones = text.tones
                        let rawText: String = text.removedTones()
                        let candidates: [Candidate] = search(text: rawText, segmentation: segmentation)
                        let qualified = candidates.compactMap({ item -> Candidate? in
                                let continuous = item.romanization.removedSpaces()
                                let continuousTones = continuous.tones
                                switch (textTones.count, continuousTones.count) {
                                case (1, 1):
                                        guard textTones == continuousTones else { return nil }
                                        let isCorrectPosition: Bool = text.dropFirst(item.input.count).first?.isTone ?? false
                                        guard isCorrectPosition else { return nil }
                                        let combinedInput = item.input + textTones
                                        return Candidate(text: item.text, romanization: item.romanization, input: combinedInput, notation: item.notation)
                                case (1, 2):
                                        let isToneLast: Bool = text.last?.isTone ?? false
                                        if isToneLast {
                                                guard continuousTones.hasSuffix(textTones) else { return nil }
                                                let isCorrectPosition: Bool = text.dropFirst(item.input.count).first?.isTone ?? false
                                                guard isCorrectPosition else { return nil }
                                                return Candidate(text: item.text, romanization: item.romanization, input: text, notation: item.notation)
                                        } else {
                                                guard continuousTones.hasPrefix(textTones) else { return nil }
                                                let combinedInput = item.input + textTones
                                                return Candidate(text: item.text, romanization: item.romanization, input: combinedInput, notation: item.notation)
                                        }
                                case (2, 1):
                                        guard textTones.hasPrefix(continuousTones) else { return nil }
                                        let isCorrectPosition: Bool = text.dropFirst(item.input.count).first?.isTone ?? false
                                        guard isCorrectPosition else { return nil }
                                        let combinedInput = item.input + continuousTones
                                        return Candidate(text: item.text, romanization: item.romanization, input: combinedInput, notation: item.notation)
                                case (2, 2):
                                        guard textTones == continuousTones else { return nil }
                                        let isToneLast: Bool = text.last?.isTone ?? false
                                        if isToneLast {
                                                guard item.input.count == (text.count - 2) else { return nil }
                                                return Candidate(text: item.text, romanization: item.romanization, input: text, notation: item.notation)
                                        } else {
                                                let tail = text.dropFirst(item.input.count + 1)
                                                let isCorrectPosition: Bool = tail.first == textTones.last
                                                guard isCorrectPosition else { return nil }
                                                let combinedInput = item.input + textTones
                                                return Candidate(text: item.text, romanization: item.romanization, input: combinedInput, notation: item.notation)
                                        }
                                default:
                                        if continuous.hasPrefix(text) {
                                                return Candidate(text: item.text, romanization: item.romanization, input: text, notation: item.notation)
                                        } else if text.hasPrefix(continuous) {
                                                return Candidate(text: item.text, romanization: item.romanization, input: continuous, notation: item.notation)
                                        } else {
                                                return nil
                                        }
                                }
                        })
                        return qualified
                case (true, false):
                        let textSeparators = text.filter(\.isSeparator)
                        let textParts = text.split(separator: "'")
                        let isHeadingSeparator: Bool = text.first?.isSeparator ?? false
                        let isTrailingSeparator: Bool = text.last?.isSeparator ?? false
                        let rawText: String = text.removedSeparators()
                        let candidates: [Candidate] = search(text: rawText, segmentation: segmentation)
                        let qualified = candidates.compactMap({ item -> Candidate? in
                                let syllables = item.romanization.removedTones().split(separator: " ")
                                guard syllables != textParts else { return Candidate(text: item.text, romanization: item.romanization, input: text, notation: item.notation) }
                                guard !(isHeadingSeparator) else { return nil }
                                switch textSeparators.count {
                                case 1 where isTrailingSeparator:
                                        guard syllables.count == 1 else { return nil }
                                        let isLengthMatched: Bool = item.input.count == (text.count - 1)
                                        guard isLengthMatched else { return nil }
                                        return Candidate(text: item.text, romanization: item.romanization, input: text, notation: item.notation)
                                case 1:
                                        switch syllables.count {
                                        case 1:
                                                guard item.input == textParts.first! else { return nil }
                                                let combinedInput: String = item.input + "'"
                                                return Candidate(text: item.text, romanization: item.romanization, input: combinedInput, notation: item.notation)
                                        case 2:
                                                guard syllables.first == textParts.first else { return nil }
                                                let combinedInput: String = item.input + "'"
                                                return Candidate(text: item.text, romanization: item.romanization, input: combinedInput, notation: item.notation)
                                        default:
                                                return nil
                                        }
                                case 2 where isTrailingSeparator:
                                        switch syllables.count {
                                        case 1:
                                                guard item.input == textParts.first! else { return nil }
                                                let combinedInput: String = item.input + "'"
                                                return Candidate(text: item.text, romanization: item.romanization, input: combinedInput, notation: item.notation)
                                        case 2:
                                                let isLengthMatched: Bool = item.input.count == (text.count - 2)
                                                guard isLengthMatched else { return nil }
                                                guard syllables.first == textParts.first else { return nil }
                                                return Candidate(text: item.text, romanization: item.romanization, input: text, notation: item.notation)
                                        default:
                                                return nil
                                        }
                                default:
                                        let textPartCount = textParts.count
                                        let syllableCount = syllables.count
                                        guard syllableCount < textPartCount else { return nil }
                                        let checks = (0..<syllableCount).map { index -> Bool in
                                                return syllables[index] == textParts[index]
                                        }
                                        let isMatched = checks.reduce(true, { $0 && $1 })
                                        guard isMatched else { return nil }
                                        let tail: [Character] = Array(repeating: "i", count: syllableCount - 1)
                                        let combinedInput: String = item.input + tail
                                        return Candidate(text: item.text, romanization: item.romanization, input: combinedInput, notation: item.notation)
                                }
                        })
                        guard qualified.isEmpty else { return qualified }
                        let anchors = textParts.compactMap(\.first)
                        let anchorCount = anchors.count
                        return shortcut(text: String(anchors))
                                .filter({ item -> Bool in
                                        let syllables = item.romanization.split(separator: Character.space).map({ $0.dropLast() })
                                        guard syllables.count == anchorCount else { return false }
                                        let checks = (0..<anchorCount).map({ index -> Bool in
                                                let part = textParts[index]
                                                let isAnchorOnly = part.count == 1
                                                return isAnchorOnly ? syllables[index].hasPrefix(part) : syllables[index] == part
                                        })
                                        return checks.reduce(true, { $0 && $1 })
                                })
                                .map({ Candidate(text: $0.text, romanization: $0.romanization, input: text, notation: $0.notation) })
                case (false, false):
                        guard segmentation.maxSchemeLength > 0 else { return processVerbatim(text: text) }
                        return process(text: text, segmentation: segmentation, needsSymbols: needsSymbols)
                }
        }

        private static func processVerbatim(text: String, limit: Int? = nil) -> [Candidate] {
                guard canProcess(text) else { return [] }
                let rounds = (0..<text.count).map({ number -> [Candidate] in
                        let leading: String = String(text.dropLast(number))
                        return match(text: leading, input: leading, limit: limit) + shortcut(text: leading, limit: limit)
                })
                return rounds.flatMap({ $0 }).uniqued()
        }

        static func canProcess(_ text: String) -> Bool {
                guard let anchor = text.first else { return false }
                let code: Int = (anchor == "y") ? "j".hash : String(anchor).hash
                let query: String = "SELECT rowid FROM lexicontable WHERE shortcut = \(code) LIMIT 1;"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else { return false }
                guard sqlite3_step(statement) == SQLITE_ROW else { return false }
                return true
        }

        private static func process(text: String, segmentation: Segmentation, needsSymbols: Bool, limit: Int? = nil) -> [Candidate] {
                guard canProcess(text) else { return [] }
                let textCount = text.count
                let primary: [Candidate] = query(text: text, segmentation: segmentation, needsSymbols: needsSymbols, limit: limit)
                guard let firstInputCount = primary.first?.input.count else { return processVerbatim(text: text, limit: 4) }
                guard firstInputCount != textCount else { return primary }
                let prefixes: [Candidate] = {
                        guard segmentation.maxSchemeLength < textCount else { return [] }
                        let shortcuts = segmentation.map({ scheme -> [Candidate] in
                                let tail = text.dropFirst(scheme.length)
                                guard let lastAnchor = tail.first else { return [] }
                                let schemeAnchors = scheme.compactMap(\.text.first)
                                let anchors: String = String(schemeAnchors + [lastAnchor])
                                let text2mark: String = scheme.map(\.text).joined(separator: " ") + " " + tail
                                return shortcut(text: anchors, limit: limit)
                                        .filter({ $0.romanization.removedTones().hasPrefix(text2mark) })
                                        .map({ Candidate(text: $0.text, romanization: $0.romanization, input: text, mark: text2mark, notation: $0.notation) })
                        })
                        return shortcuts.flatMap({ $0 })
                }()
                guard prefixes.isEmpty else { return prefixes + primary }
                let headTexts = primary.map(\.input).uniqued()
                let concatenated = headTexts.map { headText -> [Candidate] in
                        let headInputCount = headText.count
                        let tailText = String(text.dropFirst(headInputCount))
                        guard canProcess(tailText) else { return [] }
                        let tailSegmentation = Segmentor.segment(text: tailText)
                        let tailCandidates = process(text: tailText, segmentation: tailSegmentation, needsSymbols: needsSymbols, limit: 8).prefix(100)
                        guard tailCandidates.isNotEmpty else { return [] }
                        let headCandidates = primary.filter({ $0.input == headText }).prefix(8)
                        let combines = headCandidates.map({ head -> [Candidate] in
                                return tailCandidates.compactMap({ head + $0 })
                        })
                        return combines.flatMap({ $0 })
                }
                let preferredConcatenated = concatenated.flatMap({ $0 }).uniqued().preferred(with: text).prefix(1)
                return preferredConcatenated + primary
        }

        private static func query(text: String, segmentation: Segmentation, needsSymbols: Bool, limit: Int? = nil) -> [Candidate] {
                let textCount = text.count
                let searches = search(text: text, segmentation: segmentation, limit: limit)
                let preferredSearches = searches.filter({ $0.input.count == textCount })
                let matched = match(text: text, input: text, limit: limit)
                let regularCandidates: [Candidate] = {
                        var items = matched + preferredSearches
                        guard items.isNotEmpty else { return items }
                        guard limit == nil else { return items }
                        guard needsSymbols else { return items }
                        let symbols: [Candidate] = Engine.searchSymbols(text: text, segmentation: segmentation)
                        guard symbols.isNotEmpty else { return items }
                        for symbol in symbols.reversed() {
                                if let index = items.firstIndex(where: { $0.lexiconText == symbol.lexiconText }) {
                                        items.insert(symbol, at: index + 1)
                                }
                        }
                        return items
                }()
                return (regularCandidates + shortcut(text: text, limit: limit) + searches).uniqued()
        }

        private static func search(text: String, segmentation: Segmentation, limit: Int? = nil) -> [Candidate] {
                let textCount: Int = text.count
                let perfectSchemes = segmentation.filter({ $0.length == textCount })
                if perfectSchemes.isNotEmpty {
                        let matches = perfectSchemes.map({ scheme -> [Candidate] in
                                var queries: [[Candidate]] = []
                                for number in (0..<scheme.count) {
                                        let slice = scheme.dropLast(number)
                                        let pingText = slice.map(\.origin).joined()
                                        let inputText = slice.map(\.text).joined()
                                        let text2mark = slice.map(\.text).joined(separator: " ")
                                        let matched = match(text: pingText, input: inputText, mark: text2mark, limit: limit)
                                        queries.append(matched)
                                }
                                return queries.flatMap({ $0 })
                        })
                        return matches.flatMap({ $0 }).ordered(with: textCount)
                } else {
                        let matches = segmentation.map({ scheme -> [Candidate] in
                                let pingText = scheme.map(\.origin).joined()
                                let inputText = scheme.map(\.text).joined()
                                let text2mark = scheme.map(\.text).joined(separator: " ")
                                return match(text: pingText, input: inputText, mark: text2mark, limit: limit)
                        })
                        return matches.flatMap({ $0 }).ordered(with: textCount)
                }
        }


        // MARK: - SQLite

        private static func shortcut(text: String, limit: Int? = nil) -> [Candidate] {
                var candidates: [Candidate] = []
                let code: Int = text.replacingOccurrences(of: "y", with: "j").hash
                let limit: Int = limit ?? 50
                let command: String = "SELECT word, romanization, frequency, altfrequency, pronunciationorder, sandhi, literarycolloquial, partofspeech, register, label, normalized, written, vernacular, collocation, english, urdu, nepali, hindi, indonesian FROM lexicontable WHERE shortcut = \(code) LIMIT \(limit);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return candidates }
                while sqlite3_step(statement) == SQLITE_ROW {
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
                        let candidate = Candidate(text: word, romanization: romanization, input: text, notation: notation)
                        candidates.append(candidate)
                }
                return candidates
        }
        private static func match(text: String, input: String, mark: String? = nil, limit: Int? = nil) -> [Candidate] {
                var candidates: [Candidate] = []
                let code: Int = text.hash
                let limit: Int = limit ?? -1
                let command: String = "SELECT rowid, word, romanization, frequency, altfrequency, pronunciationorder, sandhi, literarycolloquial, partofspeech, register, label, normalized, written, vernacular, collocation, english, urdu, nepali, hindi, indonesian FROM lexicontable WHERE ping = \(code) LIMIT \(limit);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return candidates }
                while sqlite3_step(statement) == SQLITE_ROW {
                        let order: Int = Int(sqlite3_column_int64(statement, 0))
                        let word: String = String(cString: sqlite3_column_text(statement, 1))
                        let romanization: String = String(cString: sqlite3_column_text(statement, 2))
                        let mark: String = mark ?? romanization.removedTones()
                        let frequency: Int = Int(sqlite3_column_int64(statement, 3))
                        let altFrequency: Int = Int(sqlite3_column_int64(statement, 4))
                        let pronunciationOrder: Int = Int(sqlite3_column_int64(statement, 5))
                        let sandhi: Int = Int(sqlite3_column_int64(statement, 6))
                        let literaryColloquial: String = String(cString: sqlite3_column_text(statement, 7))
                        let partOfSpeech: String = String(cString: sqlite3_column_text(statement, 8))
                        let register: String = String(cString: sqlite3_column_text(statement, 9))
                        let label: String = String(cString: sqlite3_column_text(statement, 10))
                        let normalized: String = String(cString: sqlite3_column_text(statement, 11))
                        let written: String = String(cString: sqlite3_column_text(statement, 12))
                        let vernacular: String = String(cString: sqlite3_column_text(statement, 13))
                        let collocation: String = String(cString: sqlite3_column_text(statement, 14))
                        let english: String = String(cString: sqlite3_column_text(statement, 15))
                        let urdu: String = String(cString: sqlite3_column_text(statement, 16))
                        let nepali: String = String(cString: sqlite3_column_text(statement, 17))
                        let hindi: String = String(cString: sqlite3_column_text(statement, 18))
                        let indonesian: String = String(cString: sqlite3_column_text(statement, 19))
                        let isSandhi: Bool = sandhi == 1
                        let notation: Notation = Notation(word: word, jyutping: romanization, frequency: frequency, altFrequency: altFrequency, pronunciationOrder: pronunciationOrder, isSandhi: isSandhi, literaryColloquial: literaryColloquial, partOfSpeech: partOfSpeech, register: register, label: label, normalized: normalized, written: written, vernacular: vernacular, collocation: collocation, english: english, urdu: urdu, nepali: nepali, hindi: hindi, indonesian: indonesian)
                        let candidate = Candidate(text: word, romanization: romanization, input: input, mark: mark, order: order, notation: notation)
                        candidates.append(candidate)
                }
                return candidates
        }
}

extension Array where Element == Candidate {

        /// Sort Candidates with input text, input.count and text.count
        /// - Parameter text: Input text
        /// - Returns: Preferred Candidates
        func preferred(with text: String) -> [Candidate] {
                let sortedSelf = self.sorted { (lhs, rhs) -> Bool in
                        let lhsInputCount: Int = lhs.input.count
                        let rhsInputCount: Int = rhs.input.count
                        guard lhsInputCount == rhsInputCount else {
                                return lhsInputCount > rhsInputCount
                        }
                        return lhs.text.count < rhs.text.count
                }
                let matched = sortedSelf.filter({ $0.romanization.removedSpacesTones() == text })
                return matched.isEmpty ? sortedSelf : matched
        }

        /// Sort Candidates with UserInputTextCount and Candidate.order
        /// - Parameter textCount: User input text count
        /// - Returns: Sorted Candidates
        func ordered(with textCount: Int) -> [Candidate] {
                return self.sorted { (lhs, rhs) -> Bool in
                        let lhsInputCount: Int = lhs.input.count
                        let rhsInputCount: Int = rhs.input.count
                        if lhsInputCount == textCount && rhsInputCount != textCount {
                                return true
                        } else if lhs.order < rhs.order - 50000 {
                                return true
                        } else {
                                return lhsInputCount > rhsInputCount
                        }
                }
        }
}
