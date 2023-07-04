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

        public let word: String

        public let jyutping: String

        /// smaller is preferred
        public let pronunciationOrder: Int

        /// 變調
        public let isSandhi: Bool

        /// 無: 0, 文讀: -1, 白讀: 1
        public let literaryColloquial: Int

        /// higher is preferred
        public let frequency: Int

        public let altFrequency: Int

        /// 詞性
        public let partOfSpeech: String

        /// 語體 / 語域
        public let register: String

        public let label: String

        /// 對應嘅書面語
        public let written: String

        /// 對應嘅口語
        public let colloquial: String

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
