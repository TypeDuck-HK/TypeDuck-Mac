import Foundation
import SQLite3

public struct SyllableDBHandler {

        private static var database: OpaquePointer? = nil

        public static func prepare() {
                guard sqlite3_open_v2(":memory:", &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else { return }
                createSyllableTable()
                backupInMemoryDatabase()
                sqlite3_close_v2(database)
        }

        private static func backupInMemoryDatabase() {
                let path = "../CoreIME/Sources/CoreIME/Resources/syllabledb.sqlite3"
                if FileManager.default.fileExists(atPath: path) {
                        try? FileManager.default.removeItem(atPath: path)
                }
                var destination: OpaquePointer? = nil
                defer { sqlite3_close_v2(destination) }
                guard sqlite3_open_v2(path, &destination, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else { return }
                let backup = sqlite3_backup_init(destination, "main", database, "main")
                guard sqlite3_backup_step(backup, -1) == SQLITE_DONE else { return }
                guard sqlite3_backup_finish(backup) == SQLITE_OK else { return }
        }

        private static func createSyllableTable() {
                let createTable: String = "CREATE TABLE syllabletable(code INTEGER NOT NULL PRIMARY KEY, token TEXT NOT NULL, origin TEXT NOT NULL);"
                var createStatement: OpaquePointer? = nil
                guard sqlite3_prepare_v2(database, createTable, -1, &createStatement, nil) == SQLITE_OK else { sqlite3_finalize(createStatement); return }
                guard sqlite3_step(createStatement) == SQLITE_DONE else { sqlite3_finalize(createStatement); return }
                sqlite3_finalize(createStatement)
                guard let url = Bundle.module.url(forResource: "syllable", withExtension: "txt") else { return }
                guard let content = try? String(contentsOf: url) else { return }
                let sourceLines: [String] = content.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
                let entries = sourceLines.map { line -> String? in
                        let parts = line.split(separator: "\t")
                        guard parts.count == 3 else { return nil }
                        let code = parts[0]
                        let token = parts[1]
                        let origin = parts[2]
                        return "(\(code), '\(token)', '\(origin)')"
                }
                let values: String = entries.compactMap({ $0 }).joined(separator: ", ")
                let insertValues: String = "INSERT INTO syllabletable (code, token, origin) VALUES \(values);"
                var insertStatement: OpaquePointer? = nil
                defer { sqlite3_finalize(insertStatement) }
                guard sqlite3_prepare_v2(database, insertValues, -1, &insertStatement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(insertStatement) == SQLITE_DONE else { return }
        }
}
