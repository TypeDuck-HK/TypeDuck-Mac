public struct Notation: Hashable {

        // Equatable
        public static func ==(lhs: Notation, rhs: Notation) -> Bool {
                return lhs.word == rhs.word && lhs.jyutping == rhs.jyutping
        }

        // Hashable
        public func hash(into hasher: inout Hasher) {
                hasher.combine(word)
                hasher.combine(jyutping)
        }

        /// Cantonese
        public let word: String

        /// Romanization
        public let jyutping: String

        /// higher is preferred
        public let frequency: Int

        /// (Currently unused)
        public let altFrequency: Int

        /// smaller is preferred
        public let pronunciationOrder: Int

        /// 變調
        public let isSandhi: Bool

        /// 文讀 / 白讀
        public let literaryColloquial: String

        /// 詞性
        public let partOfSpeech: String

        /// 語體 / 語域
        public let register: String

        /// place, name, etc.
        public let label: String

        /// Standard Form
        public let normalized: String

        /// Written Form. 對應嘅書面語
        public let written: String

        /// Vernacular Form. 對應嘅口語
        public let vernacular: String

        /// Word Form. 詞組
        public let collocation: String

        /// 英語
        public let english: String

        /// 烏爾都語. RTL
        public let urdu: String

        /// 尼泊爾語
        public let nepali: String

        /// 印地語
        public let hindi: String

        /// 印尼語
        public let indonesian: String
}
