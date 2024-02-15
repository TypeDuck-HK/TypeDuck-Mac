import SwiftUI
import CoreIME

struct NotationView: View {

        init(notation: Notation, comments: [Comment]) {
                self.notation = notation
                self.partOfSpeechList = Decorator.partOfSpeechList(of: notation.partOfSpeech)
                self.labelList = Decorator.labelList(of: notation.label)
                self.dataList = Decorator.dataList(of: notation)
                self.commentList = comments.filter(\.language.isTranslation)
        }

        private let notation: Notation
        private let partOfSpeechList: [String]
        private let labelList: [String]
        private let dataList: [KeyValue]
        private let commentList: [Comment]

        var body: some View {
                VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .firstTextBaseline, spacing: 16) {
                                Text(verbatim: notation.word)
                                        .font(.system(size: 32))
                                Text(verbatim: notation.jyutping)
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                if let pronunciationType = Decorator.pronunciationType(of: notation) {
                                        Text(verbatim: pronunciationType)
                                                .font(.title3)
                                                .foregroundColor(.secondary)
                                }
                        }
                        .fixedSize()
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                                if !partOfSpeechList.isEmpty {
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                ForEach(0..<partOfSpeechList.count, id: \.self) { index in
                                                        Text(verbatim: partOfSpeechList[index])
                                                                .font(.body.weight(.light))
                                                                .foregroundColor(.secondary)
                                                                .padding(3)
                                                                .overlay {
                                                                    RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color.secondary, lineWidth: 0.75)
                                                                }
                                                }
                                        }
                                }
                                if let register = Decorator.register(of: notation.register) {
                                        Text(verbatim: register)
                                                .font(.body.italic())
                                                .foregroundColor(.secondary)
                                }
                                if !labelList.isEmpty {
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                ForEach(0..<labelList.count, id: \.self) { index in
                                                        Text(verbatim: labelList[index])
                                                                .font(.body)
                                                                .foregroundColor(.secondary)
                                                }
                                        }
                                }
                                if let definition = commentList.first {
                                        Text(verbatim: definition.text)
                                                .font(definition.language.font)
                                }
                        }
                        .fixedSize()
                        if !dataList.isEmpty {
                                if #available(macOS 13.0, *) {
                                        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 8) {
                                                ForEach(0..<dataList.count, id: \.self) { index in
                                                        GridRow {
                                                                Text(verbatim: dataList[index].titleKey)
                                                                        .font(.headline)
                                                                        .foregroundColor(.secondary)
                                                                        .gridColumnAlignment(.trailing)
                                                                Text(verbatim: dataList[index].textValue)
                                                                        .font(.body)
                                                        }
                                                }
                                        }
                                        .fixedSize()
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                                ForEach(0..<dataList.count, id: \.self) { index in
                                                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                                                                Text(verbatim: dataList[index].titleKey)
                                                                        .font(.headline)
                                                                        .foregroundColor(.secondary)
                                                                        .frame(width: 100, alignment: .trailing)
                                                                Text(verbatim: dataList[index].textValue)
                                                                        .font(.body)
                                                        }
                                                }
                                        }
                                        .fixedSize()
                                }
                        }
                        if commentList.count > 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                        Text(verbatim: "More Languages")
                                            .font(.title3.bold())
                                        if #available(macOS 13.0, *) {
                                                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 8) {
                                                        ForEach(1..<commentList.count, id: \.self) { index in
                                                                GridRow {
                                                                        Text(verbatim: commentList[index].language.name)
                                                                                .font(.headline)
                                                                                .foregroundColor(.secondary)
                                                                                .gridColumnAlignment(.trailing)
                                                                        Text(verbatim: commentList[index].text)
                                                                                .font(commentList[index].language.font)
                                                                }
                                                                .padding(commentList[index].language.padding)
                                                        }
                                                }
                                                .fixedSize()
                                        } else {
                                                VStack(alignment: .leading, spacing: 8) {
                                                        ForEach(1..<commentList.count, id: \.self) { index in
                                                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                                                        Text(verbatim: commentList[index].language.name)
                                                                                .font(.headline)
                                                                                .foregroundColor(.secondary)
                                                                                .frame(width: 100, alignment: .trailing)
                                                                        Text(verbatim: commentList[index].text)
                                                                                .font(commentList[index].language.font)
                                                                }
                                                                .padding(commentList[index].language.padding)
                                                        }
                                                }
                                                .fixedSize()
                                        }
                                }
                        }
                }
        }
}

#Preview {
        NotationView(notation: .example, comments: DisplayCandidate(candidate: .example, candidateIndex: 3).comments)
}

struct Decorator {
    
        static func pronunciationType(of notation: Notation) -> String? {
                var pronunciationType = [String]()
                if notation.isSandhi {
                        pronunciationType.append("changed tone 變音")
                }
                if let reading = Decorator.literaryColloquialReading(of: notation.literaryColloquial) {
                        pronunciationType.append(reading)
                }
                if !pronunciationType.isEmpty {
                        return "(\(pronunciationType.joined()))"
                }
                return nil
        }

        static func partOfSpeechList(of text: String) -> [String] {
                guard text.isValid else { return [] }
                let list = text.split(separator: " ").compactMap({ partOfSpeechMap[$0] })
                return list.uniqued()
        }
        private static let partOfSpeechMap: [String.SubSequence: String] = [
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
                        return nil
                }
        }

        static func register(of text: String) -> String? {
                guard text.isValid else { return nil }
                return registerMap[text]
        }
        private static let registerMap: [String: String] = [
                "wri": "written 書面語",
                "ver": "vernacular 口語",
                "for": "formal 公文體",
                "lzh": "classical chinese 文言",
        ]

        static func labelList(of text: String) -> [String] {
                guard text.isValid else { return [] }
                let labels = text.split(separator: " ").compactMap({ rawLabel -> String? in
                        guard let matched = rawLabel.split(separator: "_").compactMap({ labelMap[$0] }).first else { return nil }
                        return "(\(matched))"
                })
                return labels.uniqued()
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
    
        fileprivate static func dataList(of notation: Notation) -> [KeyValue] {
                var dataList: [KeyValue] = []
                if notation.normalized.isValid {
                        let pair: KeyValue = KeyValue(titleKey: "Standard Form 標準字形", textValue: notation.normalized)
                        dataList.append(pair)
                }
                if notation.written.isValid {
                        let pair: KeyValue = KeyValue(titleKey: "Written Form 書面語", textValue: notation.written)
                        dataList.append(pair)
                }
                if notation.vernacular.isValid {
                        let pair: KeyValue = KeyValue(titleKey: "Vernacular Form 口語", textValue: notation.vernacular)
                        dataList.append(pair)
                }
                if notation.collocation.isValid {
                        let pair: KeyValue = KeyValue(titleKey: "Collocation 配搭", textValue: notation.collocation)
                        dataList.append(pair)
                }
                return dataList
        }
}

private struct KeyValue {
        let titleKey: String
        let textValue: String
}
