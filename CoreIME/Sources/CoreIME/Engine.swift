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
                #if os(iOS)
                guard sqlite3_open_v2(path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return }
                #else
                guard sqlite3_open_v2(path, &storageDatabase, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return }
                guard sqlite3_open_v2(":memory:", &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else { return }
                let backup = sqlite3_backup_init(database, "main", storageDatabase, "main")
                guard sqlite3_backup_step(backup, -1) == SQLITE_DONE else { return }
                guard sqlite3_backup_finish(backup) == SQLITE_OK else { return }
                sqlite3_close_v2(storageDatabase)
                #endif
                isDatabaseReady = true
        }


        // MARK: - Suggestion

        public static func suggest(text: String, segmentation: Segmentation) -> [Candidate] {
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
                        return dispatch(text: text, segmentation: segmentation)
                }
        }

        private static func dispatch(text: String, segmentation: Segmentation) -> [CoreCandidate] {
                switch (text.hasSeparators, text.hasTones) {
                case (true, true):
                        let syllable = text.removedSeparatorsTones()
                        let candidates = match(text: syllable, input: text)
                        let filtered = candidates.filter({ text.hasPrefix($0.romanization) })
                        return filtered
                case (false, true):
                        let candidates: [Candidate] = match(segmentation: segmentation)
                        let qualified = candidates.map({ item -> Candidate? in
                                let continuous = item.romanization.removedSpaces()
                                if continuous.hasPrefix(text) {
                                        return Candidate(text: item.text, romanization: item.romanization, input: text, notation: item.notation)
                                } else if text.hasPrefix(continuous) {
                                        return Candidate(text: item.text, romanization: item.romanization, input: continuous, notation: item.notation)
                                } else {
                                        return nil
                                }
                        })
                        return qualified.compactMap({ $0 })
                case (true, false):
                        let candidates: [Candidate] = match(segmentation: segmentation)
                        let textParts = text.split(separator: "'")
                        let textPartCount = textParts.count
                        let qualified = candidates.map({ item -> Candidate? in
                                let syllables = item.romanization.removedTones().split(separator: " ")
                                guard syllables != textParts else { return Candidate(text: item.text, romanization: item.romanization, input: text, notation: item.notation) }
                                let syllableCount = syllables.count
                                guard syllableCount < textPartCount else { return nil }
                                let checks = (0..<syllableCount).map { index -> Bool in
                                        let syllable = syllables[index]
                                        let part = textParts[index]
                                        return syllable == part
                                }
                                let isMatched = checks.reduce(true, { $0 && $1 })
                                guard isMatched else { return nil }
                                let tail: [Character] = Array(repeating: "i", count: syllableCount - 1)
                                let input: String = item.input + tail
                                return Candidate(text: item.text, romanization: item.romanization, input: input, notation: item.notation)

                        })
                        return qualified.compactMap({ $0 })
                case (false, false):
                        return process(text: text, segmentation: segmentation)
                }
        }

        private static func processVerbatim(text: String, limit: Int? = nil) -> [CoreCandidate] {
                let rounds = (0..<text.count).map({ number -> [CoreCandidate] in
                        let leading: String = String(text.dropLast(number))
                        return match(text: leading, input: text, limit: limit) + shortcut(text: leading, limit: limit)
                })
                return rounds.flatMap({ $0 }).uniqued()
        }

        private static func process(text: String, segmentation: Segmentation, limit: Int? = nil) -> [CoreCandidate] {
                guard segmentation.maxLength > 0 else { return processVerbatim(text: text, limit: limit) }
                let textCount = text.count
                let fullMatch = match(text: text, input: text, limit: limit)
                let fullShortcut = shortcut(text: text, limit: limit)
                let candidates = match(segmentation: segmentation, limit: limit)
                let perfectCandidates = candidates.filter({ $0.input.count == textCount })
                let primary: [CoreCandidate] = (fullMatch + perfectCandidates + fullShortcut + candidates).uniqued()
                guard let firstInputCount = primary.first?.input.count else { return processVerbatim(text: text, limit: 4) }
                guard firstInputCount != textCount else { return primary }
                let anchorsArray: [String] = segmentation.map({ scheme -> String in
                        let last = text.dropFirst(scheme.length).first
                        let schemeAnchors = scheme.map(\.text.first)
                        let anchors = (schemeAnchors + [last]).compactMap({ $0 })
                        return String(anchors)
                })
                let prefixes: [CoreCandidate] = anchorsArray.uniqued().map({ shortcut(text: $0, limit: limit) }).flatMap({ $0 })
                        .filter({ $0.romanization.removedSpacesTones().hasPrefix(text) })
                        .map({ CoreCandidate(text: $0.text, romanization: $0.romanization, input: text, notation: $0.notation) })
                guard prefixes.isEmpty else { return (prefixes + candidates).uniqued() }
                let tailText: String = String(text.dropFirst(firstInputCount))
                guard canProcess(text: tailText) else { return primary }
                let tailSegmentation = Segmentor.segment(text: tailText)
                let tailCandidates: [CoreCandidate] = process(text: tailText, segmentation: tailSegmentation, limit: 4)
                guard !(tailCandidates.isEmpty) else { return primary }
                let qualified = candidates.enumerated().filter({ $0.offset < 3 && $0.element.input.count == firstInputCount })
                let combines = tailCandidates.map { tail -> [CoreCandidate] in
                        return qualified.map({ $0.element + tail })
                }
                let concatenated: [CoreCandidate] = combines.flatMap({ $0 }).enumerated().filter({ $0.offset < 4 }).map(\.element)
                return (concatenated + candidates).uniqued()
        }
        private static func canProcess(text: String) -> Bool {
                guard let first = text.first else { return false }
                return !(shortcut(text: String(first), limit: 1).isEmpty)
        }

        private static func match(segmentation: Segmentation, limit: Int? = nil) -> [CoreCandidate] {
                let matches = segmentation.map({ scheme -> [CoreCandidate] in
                        let input = scheme.map(\.text).joined()
                        let ping = scheme.map(\.origin).joined()
                        return match(text: ping, input: input, limit: limit)
                })
                return matches.flatMap({ $0 })
        }


        // MARK: - SQLite

        private static func shortcut(text: String, limit: Int? = nil) -> [CoreCandidate] {
                var candidates: [CoreCandidate] = []
                let code: Int = text.replacingOccurrences(of: "y", with: "j").hash
                let limit: Int = limit ?? 50
                let query = "SELECT word, romanization, frequency, altfrequency, pronunciationorder, sandhi, literarycolloquial, partofspeech, register, label, normalized, written, vernacular, collocation, english, urdu, nepali, hindi, indonesian FROM lexicontable WHERE shortcut = \(code) LIMIT \(limit);"
                var statement: OpaquePointer? = nil
                if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
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
                                let candidate = CoreCandidate(text: word, romanization: romanization, input: text, notation: notation)
                                candidates.append(candidate)
                        }
                }
                sqlite3_finalize(statement)
                return candidates
        }
        private static func match(text: String, input: String, limit: Int? = nil) -> [CoreCandidate] {
                var candidates: [CoreCandidate] = []
                let limit: Int = limit ?? -1
                let query = "SELECT word, romanization, frequency, altfrequency, pronunciationorder, sandhi, literarycolloquial, partofspeech, register, label, normalized, written, vernacular, collocation, english, urdu, nepali, hindi, indonesian FROM lexicontable WHERE ping = \(text.hash) LIMIT \(limit);"
                var statement: OpaquePointer? = nil
                if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
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
                                let candidate = CoreCandidate(text: word, romanization: romanization, input: input, notation: notation)
                                candidates.append(candidate)
                        }
                }
                sqlite3_finalize(statement)
                return candidates
        }
}
