import Foundation

// 20230228
// Honzi,Jyutping,PronOrder,Sandhi,LitColReading,Freq,Freq2,English,Disambiguatory Information,Part of Speech,Register,Label,Written,Colloquial,Urd,Nep,Hin,Ind
//
// 20230519
// Honzi,Jyutping,PronOrder,Sandhi,LitColReading,POS,Register,Label,Freq,Freq2,Written,Colloquial,Normalized,English,Disambiguation,Urd,Nep,Hin,Ind,Note,Synonym
//
// 20230715
// Honzi,Jyutping,PronOrder,Sandhi,LitColReading,POS,Register,Label,Freq,Freq2,NormalizedForm,WrittenForm,VernacularForm,Collocation,English,Disambiguation,Urd,Nep,Hin,Ind

struct Notation: Hashable {

        // Equatable
        static func ==(lhs: Notation, rhs: Notation) -> Bool {
                return lhs.word == rhs.word && lhs.jyutping == rhs.jyutping
        }

        // Hashable
        func hash(into hasher: inout Hasher) {
                hasher.combine(word)
                hasher.combine(jyutping)
        }

        /// Cantonese
        let word: String

        /// Romanization
        let jyutping: String

        /// For querying
        let shortcut: Int

        /// For querying
        let ping: Int

        /// higher is preferred
        let frequency: Int

        /// (Currently unused)
        let altFrequency: Int

        /// smaller is preferred
        let pronunciationOrder: Int

        /// 變調
        let isSandhi: Bool

        /// 文讀 / 白讀
        let literaryColloquial: String

        /// 詞性
        let partOfSpeech: String

        /// 語體 / 語域
        let register: String

        /// place, name, etc.
        let label: String

        /// Standard Form
        let normalized: String

        /// Written Form. 對應嘅書面語
        let written: String

        /// Vernacular Form. 對應嘅口語
        let vernacular: String

        /// Word Form. 詞組
        let collocation: String

        /// 英語
        let english: String

        /// 烏爾都語. RTL
        let urdu: String

        /// 尼泊爾語
        let nepali: String

        /// 印地語
        let hindi: String

        /// 印尼語
        let indonesian: String
}


// 20230519
// Honzi,Jyutping,PronOrder,Sandhi,LitColReading,POS,Register,Label,Freq,Freq2,Written,Colloquial,Normalized,English,Disambiguation,Urd,Nep,Hin,Ind,Note,Synonym
//
// 20230715
// Honzi,Jyutping,PronOrder,Sandhi,LitColReading,POS,Register,Label,Freq,Freq2,NormalizedForm,WrittenForm,VernacularForm,Collocation,English,Disambiguation,Urd,Nep,Hin,Ind

struct NotationKey {

        init(header: String) {
                let columns: [String] = header.split(separator: "\t").map({ $0.trimmingCharacters(in: .whitespaces) }).map({ $0.lowercased() })
                self.word = columns.firstIndex(of: "honzi") ?? 0
                self.jyutping = columns.firstIndex(of: "jyutping") ?? 1
                self.frequency = columns.firstIndex(of: "freq") ?? 8
                self.altFrequency = columns.firstIndex(of: "freq2") ?? 9
                self.pronunciationOrder = columns.firstIndex(of: "pronorder") ?? 2
                self.isSandhi = columns.firstIndex(of: "sandhi") ?? 3
                self.literaryColloquial = columns.firstIndex(of: "litcolreading") ?? 4
                self.partOfSpeech = columns.firstIndex(of: "pos") ?? columns.firstIndex(of: "partofspeech") ?? columns.firstIndex(of: "part of speech") ?? 5
                self.register = columns.firstIndex(of: "register") ?? 6
                self.label = columns.firstIndex(of: "label") ?? 7
                self.normalized = columns.firstIndex(of: "normalizedform") ?? columns.firstIndex(of: "normalized") ?? 10
                self.written = columns.firstIndex(of: "writtenform") ?? columns.firstIndex(of: "written") ?? 11
                self.vernacular = columns.firstIndex(of: "vernacularform") ?? columns.firstIndex(of: "colloquial") ?? 12
                self.collocation = columns.firstIndex(of: "collocation") ?? 13
                self.english = columns.firstIndex(of: "english") ?? 14
                self.urdu = columns.firstIndex(of: "urd") ?? 16
                self.nepali = columns.firstIndex(of: "nep") ?? 17
                self.hindi = columns.firstIndex(of: "hin") ?? 18
                self.indonesian = columns.firstIndex(of: "ind") ?? 19
        }

        /// 粵語
        let word: Int

        /// 粵語拼音
        let jyutping: Int

        /// 詞頻. 越大越優先
        let frequency: Int

        /// 備用詞頻. 越大越優先
        let altFrequency: Int

        /// 讀音順序. 越細越優先
        let pronunciationOrder: Int

        /// 變調與否
        let isSandhi: Int

        /// 無: 0, 文讀: -1, 白讀: 1
        let literaryColloquial: Int

        /// 詞性
        let partOfSpeech: Int

        /// 語體／語域
        let register: Int

        /// 附加標籤
        let label: Int

        /// Standard Form
        let normalized: Int

        /// Written Form. 對應嘅書面語
        let written: Int

        /// Vernacular Form. 對應嘅口語
        let vernacular: Int

        /// Word Form. 詞組
        let collocation: Int

        /// 英語
        let english: Int

        /// 烏爾都語. RTL
        let urdu: Int

        /// 尼泊爾語
        let nepali: Int

        /// 印地語
        let hindi: Int

        /// 印尼語
        let indonesian: Int
}
