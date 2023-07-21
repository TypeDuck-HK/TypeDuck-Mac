import SwiftUI
import CoreIME

struct NotationView: View {

        init(notation: Notation) {
                self.notation = notation
                self.partOfSpeechList = Decorator.partOfSpeechList(of: notation.partOfSpeech)
        }

        private let notation: Notation
        private let partOfSpeechList: [String]

        var body: some View {
                VStack(alignment: .leading, spacing: 8) {
                        HStack {
                                ForEach(0..<partOfSpeechList.count, id: \.self) { index in
                                        Text(verbatim: partOfSpeechList[index])
                                                .padding(3)
                                                .overlay {
                                                        RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color.accentColor, lineWidth: 1)
                                                }
                                }
                                if let register = Decorator.register(of: notation.register) {
                                        Text(verbatim: register)
                                                .font(.system(.body, design: .serif))
                                                .italic()
                                }
                                if notation.isSandhi {
                                        Text(verbatim: "Changed Tone 變音")
                                                .padding(3)
                                                .overlay {
                                                        RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color.secondary, lineWidth: 1)
                                                }
                                }
                                if let reading = Decorator.literaryColloquialReading(of: notation.literaryColloquial.description) {
                                        Text(verbatim: reading)
                                                .padding(3)
                                                .foregroundStyle(Color.white)
                                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                                }
                                if notation.label.isValid {
                                        Text(verbatim: "(\(notation.label))")
                                }
                        }
                        .fixedSize()
                        if notation.normalized.isValid {
                                Text(verbatim: "Standard Form: \(notation.normalized)")
                        }
                        if notation.written.isValid {
                                Text(verbatim: "Written Form: \(notation.written)")
                        }
                        if notation.vernacular.isValid {
                                Text(verbatim: "Vernacular Form: \(notation.vernacular)")
                        }
                        if notation.collocation.isValid {
                                Text(verbatim: "Word Form: \(notation.collocation)")
                        }
                }
        }
}

private struct Decorator {

        static func partOfSpeech(of text: String ) -> String? {
                guard text.isValid else { return nil }
                return partOfSpeechMap[text] ?? text
        }
        static func partOfSpeechList(of text: String ) -> [String] {
                guard text.isValid else { return [] }
                let parts = text.split(separator: " ").map({ $0.trimmingCharacters(in: .whitespaces) }).filter({ !$0.isEmpty })
                let list = parts.map({ partOfSpeechMap[$0] }).compactMap({ $0 })
                guard list.isEmpty else { return list }
                return [text]
        }
        private static let partOfSpeechMap: [String: String] = [
                "n": "noun 名詞",
                "v": "verb 動詞",
                "adj": "adjective 形容詞",
                "adv": "adverb 副詞",
                "conj": "conjunction 連接詞",
                "prep": "preposition 前置詞",
                "pron": "pronoun 代名詞",
                "morph": "morpheme 語素",
                "mw": "measure word 量詞",
                "part": "particle 助詞",
                "oth": "other 其他",
                "x": "non-morpheme 非語素",
        ]

        static func literaryColloquialReading(of text: String) -> String? {
                guard text.isValid else { return nil }
                switch text {
                case "lit":
                        return "literary reading 文讀"
                case "col":
                        return "colloquial reading 白讀"
                default:
                        return text
                }
        }

        static func register(of text: String) -> String? {
                guard text.isValid else { return nil }
                return registerMap[text] ?? text
        }
        private static let registerMap: [String: String] = [
                "wri": "written",
                "ver": "vernacular",
                "for": "formal",
                "lzh": "archaic",
        ]
}
