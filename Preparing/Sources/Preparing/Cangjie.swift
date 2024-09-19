import Foundation
import SQLite3

struct Cangjie {
        static func generate() -> [String] {
                prepare()
                let words = DatabasePreparer.fetchLexiconWords(length: 1)
                let entries = words.map { item -> [String] in
                        let cangjie5Matches = match(cangjie5: item)
                        let cangjie3Matches = match(cangjie3: item)
                        guard !(cangjie5Matches.isEmpty && cangjie3Matches.isEmpty) else { return [] }
                        var instances: [String] = []
                        let upperBound: Int = max(cangjie5Matches.count, cangjie3Matches.count)
                        for index in 0..<upperBound {
                                let cangjie5: String = cangjie5Matches.fetch(index) ?? "X"
                                let cangjie3: String = cangjie3Matches.fetch(index) ?? "X"
                                let cj5code = cangjie5.charcode ?? 47
                                let cj3code: Int = cangjie3.charcode ?? 47
                                let cj5complex = cangjie5.count
                                let cj3conplex = cangjie3.count
                                let instance: String = "\(item)\t\(cangjie5)\t\(cj5complex)\t\(cj5code)\t\(cangjie3)\t\(cj3conplex)\t\(cj3code)"
                                instances.append(instance)
                        }
                        return instances
                }
                sqlite3_close_v2(database)
                return entries.flatMap({ $0 }).uniqued()
        }

        private static func match<T: StringProtocol>(cangjie5 text: T) -> [String] {
                var items: [String] = []
                let command: String = "SELECT cangjie FROM cangjie5table WHERE word = '\(text)';"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return [] }
                while sqlite3_step(statement) == SQLITE_ROW {
                        let cangjie: String = String(cString: sqlite3_column_text(statement, 0))
                        items.append(cangjie)
                }
                return items
        }
        private static func match<T: StringProtocol>(cangjie3 text: T) -> [String] {
                var items: [String] = []
                let command: String = "SELECT cangjie FROM cangjie3table WHERE word = '\(text)';"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return [] }
                while sqlite3_step(statement) == SQLITE_ROW {
                        let cangjie: String = String(cString: sqlite3_column_text(statement, 0))
                        items.append(cangjie)
                }
                return items
        }

        nonisolated(unsafe) private static let database: OpaquePointer? = {
                var db: OpaquePointer? = nil
                guard sqlite3_open_v2(":memory:", &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else { return nil }
                return db
        }()
        private static func prepare() {
                // guard sqlite3_open_v2(":memory:", &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else { return }
                createCangjie5Table()
                insertCangjie5Values()
                createCangjie3Table()
                insertCangjie3Values()
                createIndies()
        }
        private static func createCangjie5Table() {
                let command: String = "CREATE TABLE cangjie5table(word TEXT NOT NULL, cangjie TEXT NOT NULL);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(statement) == SQLITE_DONE else { return }
        }
        private static func insertCangjie5Values() {
                guard let url = Bundle.module.url(forResource: "cangjie5", withExtension: "txt") else { return }
                guard let sourceContent = try? String(contentsOf: url, encoding: .utf8) else { return }
                let sourceLines: [String] = sourceContent.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
                let entries = sourceLines.compactMap { sourceLine -> String? in
                        let parts = sourceLine.split(separator: "\t")
                        guard parts.count == 2 else { return nil }
                        let word = parts[0]
                        let cangjie = parts[1]
                        return "('\(word)', '\(cangjie)')"
                }
                let values: String = entries.joined(separator: ", ")
                let command: String = "INSERT INTO cangjie5table (word, cangjie) VALUES \(values);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(statement) == SQLITE_DONE else { return }
        }
        private static func createCangjie3Table() {
                let command: String = "CREATE TABLE cangjie3table(word TEXT NOT NULL, cangjie TEXT NOT NULL);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(statement) == SQLITE_DONE else { return }
        }
        private static func insertCangjie3Values() {
                guard let url = Bundle.module.url(forResource: "cangjie3", withExtension: "txt") else { return }
                guard let sourceContent = try? String(contentsOf: url, encoding: .utf8) else { return }
                let sourceLines: [String] = sourceContent.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
                let entries = sourceLines.compactMap { sourceLine -> String? in
                        let parts = sourceLine.split(separator: "\t")
                        guard parts.count == 2 else { return nil }
                        let word = parts[0]
                        let cangjie = parts[1]
                        return "('\(word)', '\(cangjie)')"
                }
                let values: String = entries.joined(separator: ", ")
                let command: String = "INSERT INTO cangjie3table (word, cangjie) VALUES \(values);"
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(statement) == SQLITE_DONE else { return }
        }
        private static func createIndies() {
                let commands: [String] = [
                        "CREATE INDEX cangjie5wordindex ON cangjie5table(word);",
                        "CREATE INDEX cangjie3wordindex ON cangjie3table(word);"
                ]
                for command in commands {
                        var statement: OpaquePointer? = nil
                        defer { sqlite3_finalize(statement) }
                        guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                        guard sqlite3_step(statement) == SQLITE_DONE else { return }
                }
        }
}
