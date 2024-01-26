import SwiftUI
import CoreIME

struct NotationView: View {

        init(notation: Notation) {
                self.notation = notation
                self.partOfSpeechList = Decorator.partOfSpeechList(of: notation.partOfSpeech)
                var formList: [KeyValue] = []
                if notation.normalized.isValid {
                        let pair: KeyValue = KeyValue(titleKey: "Standard Form 標準字形", textValue: notation.normalized)
                        formList.append(pair)
                }
                if notation.written.isValid {
                        let pair: KeyValue = KeyValue(titleKey: "Written Form 書面語", textValue: notation.written)
                        formList.append(pair)
                }
                if notation.vernacular.isValid {
                        let pair: KeyValue = KeyValue(titleKey: "Vernacular Form 口語", textValue: notation.vernacular)
                        formList.append(pair)
                }
                if notation.collocation.isValid {
                        let pair: KeyValue = KeyValue(titleKey: "Collocation 配搭", textValue: notation.collocation)
                        formList.append(pair)
                }
                self.keyValueList = formList
        }

        private let notation: Notation
        private let partOfSpeechList: [String]
        private let keyValueList: [KeyValue]

        private struct KeyValue {
                let titleKey: String
                let textValue: String
        }

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
                                        Text(verbatim: "changed tone 變音")
                                                .padding(3)
                                                .overlay {
                                                        RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color.secondary, lineWidth: 1)
                                                }
                                }
                                if let reading = Decorator.literaryColloquialReading(of: notation.literaryColloquial) {
                                        Text(verbatim: reading)
                                                .padding(3)
                                                .foregroundStyle(Color.white)
                                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                                }
                                if let labelsText = Decorator.labelsText(of: notation.label) {
                                        Text(verbatim: labelsText)
                                }
                        }
                        .fixedSize()
                        if !(keyValueList.isEmpty) {
                                if #available(macOS 13.0, *) {
                                        Grid {
                                                ForEach(0..<keyValueList.count, id: \.self) { index in
                                                        GridRow {
                                                                Text(verbatim: "\(keyValueList[index].titleKey):").gridColumnAlignment(.trailing)
                                                                Text(verbatim: keyValueList[index].textValue).gridColumnAlignment(.leading)
                                                        }
                                                }
                                        }
                                } else {
                                        ForEach(0..<keyValueList.count, id: \.self) { index in
                                                Text(verbatim: keyValueList[index].titleKey) + Text(verbatim: ": ") +  Text(verbatim: keyValueList[index].textValue)
                                        }
                                }
                        }
                }
        }
}

#Preview {
        NotationView(notation: .example)
}

private struct Decorator {

        static func partOfSpeechList(of text: String ) -> [String] {
                guard text.isValid else { return [] }
                let list = text.split(separator: " ").map({ partOfSpeechMap[$0] ?? $0 })
                return list.uniqued().map({ String($0) })
        }
        private static let partOfSpeechMap: [String.SubSequence: String.SubSequence] = [
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
                "wri": "written 書面語",
                "ver": "vernacular 口語",
                "for": "formal 公文體",
                "lzh": "classical chinese 文言",
        ]

        static func labelsText(of text: String) -> String? {
                guard text.isValid else { return nil }
                let labels = text.split(separator: " ").map({ rawLabel -> String in
                        guard let matched = rawLabel.split(separator: "_").compactMap({ labelMap[$0] }).first else {
                                return "(" + rawLabel + ")"
                        }
                        return "(" + matched + ")"
                })
                guard !(labels.isEmpty) else { return nil }
                return labels.uniqued().joined(separator: " ")
        }
        private static let labelMap: [String.SubSequence: String] = [
                "abbrev": "abbreviation 簡稱",
                "astro": "astronomy 天文",
                "ChinMeta": "sexagenary cycle 干支",
                "horo": "horoscope 星座",
                "org": "organisation 機構",
                "person": "person 人名",
                "place": "place 地名",
                "reli": "religion 宗教",
                "rare": "rare 罕見",
                "composition": "compound 詞組",
        ]
}
