import Foundation
import SQLite3
import CoreIME

struct UserLexicon {

        private static var database: OpaquePointer? = nil

        static func prepare() {
                guard database == nil else { return }
                guard let libraryDirectoryUrl: URL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }
                let userLexiconUrl: URL = libraryDirectoryUrl.appendingPathComponent("userlexicon.sqlite3", isDirectory: false)
                if sqlite3_open_v2(userLexiconUrl.path, &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK {
                        ensureTable()
                }
        }
        private static func ensureTable() {
                let command: String = "CREATE TABLE IF NOT EXISTS userlexicontable(id INTEGER NOT NULL PRIMARY KEY, frequency INTEGER NOT NULL, word TEXT NOT NULL, romanization TEXT NOT NULL, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(statement) == SQLITE_DONE else { return }
        }


        // MARK: - Handle Candidate

        static func handle(_ candidate: Candidate) {
                let word: String = candidate.lexiconText
                let romanization: String = candidate.romanization
                let id: Int64 = Int64((word + romanization).hash)
                if let frequency: Int64 = find(by: id) {
                        update(id: id, frequency: frequency + 1)
                } else {
                        let newEntry: LexiconEntry = LexiconEntry(id: id, frequency: 1, word: word, romanization: romanization, shortcut: romanization.shortcut, ping: romanization.ping)
                        insert(entry: newEntry)
                }
        }
        private static func find(by id: Int64) -> Int64? {
                let command: String = "SELECT frequency FROM userlexicontable WHERE id = \(id) LIMIT 1;"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return nil }
                guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
                let frequency: Int64 = sqlite3_column_int64(statement, 0)
                return frequency
        }
        private static func update(id: Int64, frequency: Int64) {
                let command: String = "UPDATE userlexicontable SET frequency = \(frequency) WHERE id = \(id);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(statement) == SQLITE_DONE else { return }
        }
        private static func insert(entry: LexiconEntry) {
                let command: String = "INSERT INTO userlexicontable (id, frequency, word, romanization, shortcut, ping) VALUES (?, ?, ?, ?, ?, ?);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }

                sqlite3_bind_int64(statement, 1, entry.id)
                sqlite3_bind_int64(statement, 2, entry.frequency)
                sqlite3_bind_text(statement, 3, (entry.word as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (entry.romanization as NSString).utf8String, -1, nil)
                sqlite3_bind_int64(statement, 5, entry.shortcut)
                sqlite3_bind_int64(statement, 6, entry.ping)

                guard sqlite3_step(statement) == SQLITE_DONE else { return }
        }


        // MARK: - Suggestion

        static func suggest(text: String, segmentation: Segmentation) -> [Candidate] {
                let regularMatch = match(text: text, input: text, isShortcut: false)
                let regularShortcut = match(text: text, input: text, isShortcut: true)
                let textCount = text.count
                let segmentation = segmentation.filter({ $0.length == textCount })
                guard segmentation.maxLength > 0 else {
                        return (regularMatch + regularShortcut).uniqued()
                }
                let matches = segmentation.map({ scheme -> [Candidate] in
                        let pingText = scheme.map(\.origin).joined()
                        return match(text: pingText, input: text, isShortcut: false)
                })
                let combined = regularMatch + regularShortcut + matches.flatMap({ $0 })
                return combined.uniqued()
        }

        private static func match(text: String, input: String, isShortcut: Bool) -> [Candidate] {
                var candidates: [Candidate] = []
                let code: Int = isShortcut ? text.replacingOccurrences(of: "y", with: "j").hash : text.hash
                let column: String = isShortcut ? "shortcut" : "ping"
                let command: String = "SELECT word, romanization FROM userlexicontable WHERE \(column) = \(code) ORDER BY frequency DESC LIMIT 5;"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return candidates }
                while sqlite3_step(statement) == SQLITE_ROW {
                        let word: String = String(cString: sqlite3_column_text(statement, 0))
                        let romanization: String = String(cString: sqlite3_column_text(statement, 1))
                        let candidate: Candidate = Candidate(text: word, romanization: romanization, input: input, lexiconText: word)
                        candidates.append(candidate)
                }
                return candidates
        }


        // MARK: - Delete & Clear

        /// Delete one lexicon entry
        static func removeItem(candidate: Candidate) {
                let id: Int64 = Int64((candidate.lexiconText + candidate.romanization).hash)
                let command: String = "DELETE FROM userlexicontable WHERE id = \(id) LIMIT 1;"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(statement) == SQLITE_DONE else { return }
        }

        /// Clear User Lexicon
        static func deleteAll() {
                let command = "DELETE FROM userlexicontable;"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(statement) == SQLITE_DONE else { return }
        }
}

private struct LexiconEntry {

        /// (Candidate.lexiconText + Candidate.jyutping).hash
        let id: Int64

        let frequency: Int64

        /// Candidate.lexiconText
        let word: String

        /// Jyutping
        let romanization: String

        /// jyutping.initials.hash
        let shortcut: Int64

        /// jyutping.withoutTonesAndSpaces.hash
        let ping: Int64
}
