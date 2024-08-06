import Foundation
import SQLite3

struct DatabasePreparer {

        private static var database: OpaquePointer? = nil

        static func prepare() {
                guard sqlite3_open_v2(":memory:", &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else { return }
                createLexiconTable()
                createLexiconIndies()
                createCangjieTable()
                createQuickTable()
                createStrokeTable()
                createT2STable()
                createStructureTable()
                createPinyinTable()
                createSymbolTable()
                createOtherIndies()
                backupInMemoryDatabase()
                sqlite3_close_v2(database)
        }
        private static func backupInMemoryDatabase() {
                let path = "../CoreIME/Sources/CoreIME/Resources/imedb.sqlite3"
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

        private static func createLexiconTable() {
                let createTable: String = "CREATE TABLE lexicontable(word TEXT NOT NULL, romanization TEXT NOT NULL, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL, frequency INTEGER NOT NULL, altfrequency INTEGER NOT NULL, pronunciationorder INTEGER NOT NULL, sandhi INTEGER NOT NULL, literarycolloquial TEXT NOT NULL, partofspeech TEXT NOT NULL, register TEXT NOT NULL, label TEXT NOT NULL, normalized TEXT NOT NULL, written TEXT NOT NULL, vernacular TEXT NOT NULL, collocation TEXT NOT NULL, english TEXT NOT NULL, urdu TEXT NOT NULL, nepali TEXT NOT NULL, hindi TEXT NOT NULL, indonesian TEXT NOT NULL);"
                var createStatement: OpaquePointer? = nil
                guard sqlite3_prepare_v2(database, createTable, -1, &createStatement, nil) == SQLITE_OK else { sqlite3_finalize(createStatement); return }
                guard sqlite3_step(createStatement) == SQLITE_DONE else { sqlite3_finalize(createStatement); return }
                sqlite3_finalize(createStatement)

                let notations: [Notation] = DataHandler.generateNotations()
                let entries: [String?] = notations.map { item -> String? in
                        let sandhiValue: Int = item.isSandhi ? 1 : 0
                        let text: String = "('\(item.word)', '\(item.jyutping)', \(item.shortcut), \(item.ping), \(item.frequency), \(item.altFrequency), \(item.pronunciationOrder), \(sandhiValue), '\(item.literaryColloquial)', '\(item.partOfSpeech)', '\(item.register)', '\(item.label)', '\(item.normalized)', '\(item.written)', '\(item.vernacular)', '\(item.collocation)', '\(item.english)', '\(item.urdu)', '\(item.nepali)', '\(item.hindi)', '\(item.indonesian)')"
                        return text
                }
                let items = entries.compactMap({ $0 })

                func insert(values: String) {
                        let insert: String = "INSERT INTO lexicontable (word, romanization, shortcut, ping, frequency, altfrequency, pronunciationorder, sandhi, literarycolloquial, partofspeech, register, label, normalized, written, vernacular, collocation, english, urdu, nepali, hindi, indonesian) VALUES \(values);"
                        var insertStatement: OpaquePointer? = nil
                        defer { sqlite3_finalize(insertStatement) }
                        guard sqlite3_prepare_v2(database, insert, -1, &insertStatement, nil) == SQLITE_OK else { return }
                        guard sqlite3_step(insertStatement) == SQLITE_DONE else { return }
                }
                let range: Range<Int> = 0..<2000
                let distance: Int = items.count / 2000
                let parts = range.map({ number ->  ArraySlice<String> in
                        let lastIndex: Int = number == 1999 ? items.count : ((number + 1) * distance)
                        return items[(number * distance)..<lastIndex]
                })
                for part in parts {
                        let values = part.joined(separator: ", ")
                        insert(values: values)
                }
        }
        private static func createLexiconIndies() {
                let commands: [String] = [
                        "CREATE INDEX lexiconpingindex ON lexicontable(ping);",
                        "CREATE INDEX lexiconshortcutindex ON lexicontable(shortcut);",
                        "CREATE INDEX lexiconwordindex ON lexicontable(word);"
                ]
                for command in commands {
                        var statement: OpaquePointer? = nil
                        defer { sqlite3_finalize(statement) }
                        guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                        guard sqlite3_step(statement) == SQLITE_DONE else { return }
                }
        }
        private static func createOtherIndies() {
                let commands: [String] = [
                        "CREATE INDEX cangjiecangjie5index ON cangjietable(cangjie5);",
                        "CREATE INDEX cangjiecj5codeindex ON cangjietable(cj5code);",
                        "CREATE INDEX cangjiecangjie3index ON cangjietable(cangjie3);",
                        "CREATE INDEX cangjiecj3codeindex ON cangjietable(cj3code);",

                        "CREATE INDEX quickquick5index ON quicktable(quick5);",
                        "CREATE INDEX quickq5codeindex ON quicktable(q5code);",
                        "CREATE INDEX quickquick3index ON quicktable(quick3);",
                        "CREATE INDEX quickq3codeindex ON quicktable(q3code);",

                        "CREATE INDEX strokestrokeindex ON stroketable(stroke);",
                        "CREATE INDEX strokecodeindex ON stroketable(code);",

                        "CREATE INDEX structurepingindex ON structuretable(ping);",

                        "CREATE INDEX pinyinshortcutindex ON pinyintable(shortcut);",
                        "CREATE INDEX pinyinpingindex ON pinyintable(ping);",

                        "CREATE INDEX symbolshortcutindex ON symboltable(shortcut);",
                        "CREATE INDEX symbolpingindex ON symboltable(ping);"
                ]
                for command in commands {
                        var statement: OpaquePointer? = nil
                        defer { sqlite3_finalize(statement) }
                        guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return }
                        guard sqlite3_step(statement) == SQLITE_DONE else { return }
                }
        }
        static func fetchLexiconWords(length: Int? = nil) -> [String] {
                var words: [String] = []
                let command: String = {
                        guard let length else { return "SELECT word FROM lexicontable ORDER BY frequency DESC;" }
                        return "SELECT word FROM lexicontable WHERE length(word) = \(length) ORDER BY frequency DESC;"
                }()
                var statement: OpaquePointer? = nil
                defer { sqlite3_finalize(statement) }
                guard sqlite3_prepare_v2(database, command, -1, &statement, nil) == SQLITE_OK else { return [] }
                while sqlite3_step(statement) == SQLITE_ROW {
                        let word: String = String(cString: sqlite3_column_text(statement, 0))
                        words.append(word)
                }
                return words.uniqued()
        }
        private static func createCangjieTable() {
                let createTable: String = "CREATE TABLE cangjietable(word TEXT NOT NULL, cangjie5 TEXT NOT NULL, cj5complex INTEGER NOT NULL, cj5code INTEGER NOT NULL, cangjie3 TEXT NOT NULL, cj3complex INTEGER NOT NULL, cj3code INTEGER NOT NULL);"
                var createStatement: OpaquePointer? = nil
                guard sqlite3_prepare_v2(database, createTable, -1, &createStatement, nil) == SQLITE_OK else { sqlite3_finalize(createStatement); return }
                guard sqlite3_step(createStatement) == SQLITE_DONE else { sqlite3_finalize(createStatement); return }
                sqlite3_finalize(createStatement)
                let sourceLines: [String] = Cangjie.generate()
                let entries = sourceLines.compactMap { sourceLine -> String? in
                        let parts = sourceLine.split(separator: "\t")
                        guard parts.count == 7 else { return nil }
                        let word = parts[0]
                        let cangjie5 = parts[1]
                        let cj5complex = parts[2]
                        let cj5code = parts[3]
                        let cangjie3 = parts[4]
                        let cj3complex = parts[5]
                        let cj3code = parts[6]
                        return "('\(word)', '\(cangjie5)', \(cj5complex), \(cj5code), '\(cangjie3)', \(cj3complex), \(cj3code))"
                }
                let values: String = entries.joined(separator: ", ")
                let insert: String = "INSERT INTO cangjietable (word, cangjie5, cj5complex, cj5code, cangjie3, cj3complex, cj3code) VALUES \(values);"
                var insertStatement: OpaquePointer? = nil
                defer { sqlite3_finalize(insertStatement) }
                guard sqlite3_prepare_v2(database, insert, -1, &insertStatement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(insertStatement) == SQLITE_DONE else { return }
        }
        private static func createQuickTable() {
                let createTable: String = "CREATE TABLE quicktable(word TEXT NOT NULL, quick5 TEXT NOT NULL, q5complex INTEGER NOT NULL, q5code INTEGER NOT NULL, quick3 TEXT NOT NULL, q3complex INTEGER NOT NULL, q3code INTEGER NOT NULL);"
                var createStatement: OpaquePointer? = nil
                guard sqlite3_prepare_v2(database, createTable, -1, &createStatement, nil) == SQLITE_OK else { sqlite3_finalize(createStatement); return }
                guard sqlite3_step(createStatement) == SQLITE_DONE else { sqlite3_finalize(createStatement); return }
                sqlite3_finalize(createStatement)
                let sourceLines: [String] = Quick.generate()
                func insert(values: String) {
                        let insert: String = "INSERT INTO quicktable (word, quick5, q5complex, q5code, quick3, q3complex, q3code) VALUES \(values);"
                        var insertStatement: OpaquePointer? = nil
                        defer { sqlite3_finalize(insertStatement) }
                        guard sqlite3_prepare_v2(database, insert, -1, &insertStatement, nil) == SQLITE_OK else { return }
                        guard sqlite3_step(insertStatement) == SQLITE_DONE else { return }
                }
                let range: Range<Int> = 0..<2000
                let distance: Int = sourceLines.count / 2000
                for number in range {
                        let bound: Int = number == 1999 ? sourceLines.count : ((number + 1) * distance)
                        let part = sourceLines[(number * distance)..<bound]
                        let entries = part.compactMap { line -> String? in
                                let parts = line.split(separator: "\t")
                                guard parts.count == 7 else { return nil }
                                let word = parts[0]
                                let quick5 = parts[1]
                                let q5complex = parts[2]
                                let q5code = parts[3]
                                let quick3 = parts[4]
                                let q3complex = parts[5]
                                let q3code = parts[6]
                                return "('\(word)', '\(quick5)', \(q5complex), \(q5code), '\(quick3)', \(q3complex), \(q3code))"
                        }
                        let values: String = entries.joined(separator: ", ")
                        insert(values: values)
                }
        }
        private static func createStrokeTable() {
                let createTable: String = "CREATE TABLE stroketable(word TEXT NOT NULL, stroke TEXT NOT NULL, complex INTEGER NOT NULL, code INTEGER NOT NULL);"
                var createStatement: OpaquePointer? = nil
                guard sqlite3_prepare_v2(database, createTable, -1, &createStatement, nil) == SQLITE_OK else { sqlite3_finalize(createStatement); return }
                guard sqlite3_step(createStatement) == SQLITE_DONE else { sqlite3_finalize(createStatement); return }
                sqlite3_finalize(createStatement)
                let sourceLines: [String] = Stroke.generate()
                let entries = sourceLines.compactMap { sourceLine -> String? in
                        let parts = sourceLine.split(separator: "\t")
                        guard parts.count == 4 else { return nil }
                        let word = parts[0]
                        let stroke = parts[1]
                        let complex = parts[2]
                        let code = parts[3]
                        return "('\(word)', '\(stroke)', \(complex), \(code))"
                }
                let values: String = entries.joined(separator: ", ")
                let insert: String = "INSERT INTO stroketable (word, stroke, complex, code) VALUES \(values);"
                var insertStatement: OpaquePointer? = nil
                defer { sqlite3_finalize(insertStatement) }
                guard sqlite3_prepare_v2(database, insert, -1, &insertStatement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(insertStatement) == SQLITE_DONE else { return }
        }

        private static func createT2STable() {
                let createTable: String = "CREATE TABLE t2stable(traditional INTEGER NOT NULL PRIMARY KEY, simplified TEXT NOT NULL);"
                var createStatement: OpaquePointer? = nil
                guard sqlite3_prepare_v2(database, createTable, -1, &createStatement, nil) == SQLITE_OK else { sqlite3_finalize(createStatement); return }
                guard sqlite3_step(createStatement) == SQLITE_DONE else { sqlite3_finalize(createStatement); return }
                sqlite3_finalize(createStatement)
                let entries: [String] = Hant2Hans.generate().map({ "(\($0.traditional), '\($0.simplified)')" })
                let values: String = entries.joined(separator: ", ")
                let insert: String = "INSERT INTO t2stable (traditional, simplified) VALUES \(values);"
                var insertStatement: OpaquePointer? = nil
                defer { sqlite3_finalize(insertStatement) }
                guard sqlite3_prepare_v2(database, insert, -1, &insertStatement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(insertStatement) == SQLITE_DONE else { return }
        }
        private static func createStructureTable() {
                let createTable: String = "CREATE TABLE structuretable(word TEXT NOT NULL, romanization TEXT NOT NULL, ping INTEGER NOT NULL);"
                var createStatement: OpaquePointer? = nil
                guard sqlite3_prepare_v2(database, createTable, -1, &createStatement, nil) == SQLITE_OK else { sqlite3_finalize(createStatement); return }
                guard sqlite3_step(createStatement) == SQLITE_DONE else { sqlite3_finalize(createStatement); return }
                sqlite3_finalize(createStatement)
                guard let url = Bundle.module.url(forResource: "structure", withExtension: "txt") else { return }
                guard let content = try? String(contentsOf: url) else { return }
                let sourceLines: [String] = content.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
                let entries = sourceLines.map { sourceLine -> String? in
                        let parts = sourceLine.split(separator: "\t")
                        guard parts.count == 3 else { return nil }
                        let word = parts[0]
                        let romanization = parts[1]
                        let ping = parts[2]
                        return "('\(word)', '\(romanization)', \(ping))"
                }
                let values: String = entries.compactMap({ $0 }).joined(separator: ", ")
                let insert: String = "INSERT INTO structuretable (word, romanization, ping) VALUES \(values);"
                var insertStatement: OpaquePointer? = nil
                defer { sqlite3_finalize(insertStatement) }
                guard sqlite3_prepare_v2(database, insert, -1, &insertStatement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(insertStatement) == SQLITE_DONE else { return }
        }
        private static func createPinyinTable() {
                let createTable: String = "CREATE TABLE pinyintable(word TEXT NOT NULL, pinyin TEXT NOT NULL, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL);"
                var createStatement: OpaquePointer? = nil
                guard sqlite3_prepare_v2(database, createTable, -1, &createStatement, nil) == SQLITE_OK else { sqlite3_finalize(createStatement); return }
                guard sqlite3_step(createStatement) == SQLITE_DONE else { sqlite3_finalize(createStatement); return }
                sqlite3_finalize(createStatement)
                guard let url = Bundle.module.url(forResource: "pinyin", withExtension: "txt") else { return }
                guard let content = try? String(contentsOf: url) else { return }
                let sourceLines: [String] = content.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
                func insert(values: String) {
                        let insert: String = "INSERT INTO pinyintable (word, pinyin, shortcut, ping) VALUES \(values);"
                        var insertStatement: OpaquePointer? = nil
                        defer { sqlite3_finalize(insertStatement) }
                        guard sqlite3_prepare_v2(database, insert, -1, &insertStatement, nil) == SQLITE_OK else { return }
                        guard sqlite3_step(insertStatement) == SQLITE_DONE else { return }
                }
                let range: Range<Int> = 0..<2000
                let distance: Int = sourceLines.count / 2000
                for number in range {
                        let bound: Int = number == 1999 ? sourceLines.count : ((number + 1) * distance)
                        let part = sourceLines[(number * distance)..<bound]
                        let entries = part.compactMap { line -> String? in
                                let parts = line.split(separator: "\t")
                                guard parts.count == 4 else { return nil }
                                let word = parts[0]
                                let pinyin = parts[1]
                                let shortcut = parts[2]
                                let ping = parts[3]
                                return "('\(word)', '\(pinyin)', \(shortcut), \(ping))"
                        }
                        let values: String = entries.joined(separator: ", ")
                        insert(values: values)
                }
        }
        private static func createSymbolTable() {
                let createTable: String = "CREATE TABLE symboltable(category INTEGER NOT NULL, codepoint TEXT NOT NULL, cantonese TEXT NOT NULL, romanization TEXT NOT NULL, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL);"
                var createStatement: OpaquePointer? = nil
                guard sqlite3_prepare_v2(database, createTable, -1, &createStatement, nil) == SQLITE_OK else { sqlite3_finalize(createStatement); return }
                guard sqlite3_step(createStatement) == SQLITE_DONE else { sqlite3_finalize(createStatement); return }
                sqlite3_finalize(createStatement)
                guard let url = Bundle.module.url(forResource: "symbol", withExtension: "txt") else { return }
                guard let content = try? String(contentsOf: url) else { return }
                let sourceLines: [String] = content.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
                let entries = sourceLines.map { sourceLine -> String? in
                        let parts = sourceLine.split(separator: "\t")
                        guard parts.count == 6 else { return nil }
                        let category = parts[0]
                        let codepoint = parts[1]
                        let cantonese = parts[2]
                        let romanization = parts[3]
                        let shortcut = parts[4]
                        let ping = parts[5]
                        return "(\(category), '\(codepoint)', '\(cantonese)', '\(romanization)', \(shortcut), \(ping))"
                }
                let values: String = entries.compactMap({ $0 }).joined(separator: ", ")
                let insert: String = "INSERT INTO symboltable (category, codepoint, cantonese, romanization, shortcut, ping) VALUES \(values);"
                var insertStatement: OpaquePointer? = nil
                defer { sqlite3_finalize(insertStatement) }
                guard sqlite3_prepare_v2(database, insert, -1, &insertStatement, nil) == SQLITE_OK else { return }
                guard sqlite3_step(insertStatement) == SQLITE_DONE else { return }
        }
}
