import Foundation

struct DataHandler {
        static func generateNotations() -> [Notation] {
                let sourceLines: [String] = fetchData()
                guard let header: String = sourceLines.first else { fatalError("generateNotations(): data sourceLines is empty") }
                let keys: NotationKey = NotationKey(header: header)
                let fill: [String] = Array(repeating: "X", count: 20)
                let entries: [Notation?] = sourceLines.dropFirst().map { line -> Notation? in
                        let blocks: [String] = line.split(separator: "\t", omittingEmptySubsequences: false).map({ String($0) })
                        guard !blocks.isEmpty else { return nil }
                        let parts: [String] = blocks.count >= 20 ? blocks : (blocks + fill)
                        let word = parts[keys.word]
                        let jyutping = parts[keys.jyutping]
                        let shortcut: Int = shortcutCode(of: jyutping)
                        let ping: Int = pingCode(of: jyutping)
                        let frequency: Int = {
                                let text = parts[keys.frequency].split(separator: ".").first ?? "0"
                                return Int(text) ?? 0
                        }()
                        let altFrequency: Int = {
                                let text = parts[keys.altFrequency].split(separator: ".").first ?? "0"
                                return Int(text) ?? 0
                        }()
                        let pronunciationOrder: Int = Int(parts[keys.pronunciationOrder]) ?? 1
                        let isSandhi: Bool = {
                                let text = parts[keys.isSandhi]
                                let number = Int(text)
                                return number == 1
                        }()
                        let literaryColloquial: String = parts[keys.literaryColloquial]
                        let english: String = parts[keys.english]
                        let partOfSpeech: String = parts[keys.partOfSpeech]
                        let register: String = parts[keys.register]
                        let label: String = parts[keys.label]
                        let normalized: String = parts[keys.normalized]
                        let written: String = parts[keys.written]
                        let vernacular: String = parts[keys.vernacular]
                        let collocation: String = parts[keys.collocation]
                        let urdu: String = parts[keys.urdu]
                        let nepali: String = parts[keys.nepali]
                        let hindi: String = parts[keys.hindi]
                        let indonesian: String = parts[keys.indonesian]

                        let entry: Notation = Notation(word: word, jyutping: jyutping, shortcut: shortcut, ping: ping, frequency: frequency, altFrequency: altFrequency, pronunciationOrder: pronunciationOrder, isSandhi: isSandhi, literaryColloquial: literaryColloquial, partOfSpeech: partOfSpeech, register: register, label: label, normalized: normalized, written: written, vernacular: vernacular, collocation: collocation, english: english, urdu: urdu, nepali: nepali, hindi: hindi, indonesian: indonesian)

                        return entry
                }
                return entries.compactMap({ $0 }).uniqued().sorted(by: { $0.frequency > $1.frequency })
        }

        private static func fetchData() -> [String] {
                guard let sourceUrl: URL = Bundle.module.url(forResource: "data", withExtension: "csv") else { fatalError("Can not access data.csv, file not found.") }
                guard let sourceContent: String = try? String(contentsOf: sourceUrl, encoding: .utf8) else { fatalError("Can not read data.csv content.") }
                let sourceLines: [String] = sourceContent
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: .newlines)
                        .map({ $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .controlCharacters) })
                        .filter({ !($0.isEmpty) })
                        .uniqued()
                guard !(sourceLines.isEmpty) else { fatalError("data.csv is empty.") }
                let entries = sourceLines.map({ csv2tsv(text: $0) })
                return entries
        }
        private static func csv2tsv(text: String) -> String {
                let transformed = text
                        .replacingOccurrences(of: "《", with: "")
                        .replacingOccurrences(of: "》", with: "")
                        .replacingOccurrences(of: "〈", with: "")
                        .replacingOccurrences(of: "〉", with: "")
                        .replacingOccurrences(of: ",\"", with: "《〈")
                        .replacingOccurrences(of: "\",", with: "〉》")
                let splitTexts = transformed.split(separator: "《", omittingEmptySubsequences: false).map({ $0.split(separator: "》", omittingEmptySubsequences: false) })
                let blocks = splitTexts.flatMap({ $0 })
                let processedTexts = blocks.map { block -> [String] in
                        if block.hasPrefix("〈") || block.hasSuffix("〉") {
                                let processed = block
                                        .replacingOccurrences(of: "〈", with: "")
                                        .replacingOccurrences(of: "〉", with: "")
                                        .replacingOccurrences(of: "\"\"", with: "\"")
                                        .trimmingCharacters(in: .whitespaces)
                                return [processed]
                        } else {
                                let texts = block.split(separator: ",", omittingEmptySubsequences: false)
                                return texts.map({ $0.trimmingCharacters(in: .whitespaces) })
                        }
                }
                let texts: [String] = processedTexts.flatMap({ $0 }).map({ item -> String in
                        if item.isEmpty {
                                return "X"
                        } else {
                                return item
                                        .replacingOccurrences(of: "'", with: "’")
                                        .replacingOccurrences(of: "\t\"", with: "\t“")
                                        .replacingOccurrences(of: "\"\t", with: "”\t")
                        }
                })
                return texts.joined(separator: "\t")
        }
}

private extension DataHandler {
        static func shortcutCode(of text: String) -> Int {
                guard text.contains(" ") else {
                        guard let first = text.first else { return 0 }
                        guard first.isLowercasedBasicLatinLetter else { return 0 }
                        let anchor: String = String(first)
                        return anchor.hash
                }
                let syllables = text.split(separator: " ").map({ $0.trimmingCharacters(in: .controlCharacters) })
                let anchors = syllables.map { syllable -> String? in
                        guard let first = syllable.first else { return nil }
                        guard first.isLowercasedBasicLatinLetter else { return nil }
                        return String(first)
                }
                let shortcutText = anchors.compactMap({ $0 }).joined()
                guard !(shortcutText.isEmpty) else { return 0 }
                return shortcutText.hash
        }
        static func pingCode(of text: String) -> Int {
                let filtered = text.filter({ !(spaceAndTones.contains($0)) })
                let pingText = filtered.filter({ $0.isLowercasedBasicLatinLetter })
                guard !(pingText.isEmpty) else { return 0 }
                guard pingText.count == filtered.count else { return 0 }
                return pingText.hash
        }
        static let spaceAndTones: Set<Character> = Set("123 456")
}
