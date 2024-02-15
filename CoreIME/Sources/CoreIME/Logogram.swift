/// 字符集標準
public enum Logogram: Int {

        /// Traditional. 繁體字
        case traditional = 1

        /// Simplified. 簡體字
        case simplified = 4
}

public typealias CharacterStandard = Logogram

extension CharacterStandard {

        /// self == .simplified
        public var isSimplified: Bool {
                return self == .simplified
        }

        /// self != .simplified
        public var isTraditional: Bool {
                return self != .simplified
        }
}

extension Logogram {

        public static func strokeTransform(_ text: String) -> String {
                // 橫: w, h, t: w = Waang, h = Héng, t = 提 = Tai = Tí
                // 豎: s      : s = Syu = Shù
                // 撇: a, p   : p = Pit = Piě
                // 點: d, n   : d = Dim = Diǎn, n = 捺 = Naat = Nà
                // 折: z      : z = Zit = Zhé
                // macOS built-in Stroke: https://support.apple.com/zh-hk/guide/chinese-input-method/cimskt12969/mac
                // 橫: j, KP_1
                // 豎: k, KP_2
                // 撇: l, KP_3
                // 點: u, KP_4
                // 折: i, KP_5
                return text
                        .replacingOccurrences(of: "(h|t|j|1)", with: "w", options: .regularExpression)
                        .replacingOccurrences(of: "(k|2)", with: "s", options: .regularExpression)
                        .replacingOccurrences(of: "(p|l|3)", with: "a", options: .regularExpression)
                        .replacingOccurrences(of: "(n|u|4)", with: "d", options: .regularExpression)
                        .replacingOccurrences(of: "(i|5)", with: "z", options: .regularExpression)
        }

        public static func stroke(of letter: Character) -> Character? {
                return strokeMap[letter]
        }

        public static func cangjie(of letter: Character) -> Character? {
                return cangjieMap[letter]
        }

        private static let strokeMap: [Character: Character] = ["w": "⼀", "s": "⼁", "a": "⼃", "d": "⼂", "z": "⼄"]

        private static let cangjieMap: [Character: Character] = [
                "a": "日",
                "b": "月",
                "c": "金",
                "d": "木",
                "e": "水",
                "f": "火",
                "g": "土",
                "h": "竹",
                "i": "戈",
                "j": "十",
                "k": "大",
                "l": "中",
                "m": "一",
                "n": "弓",
                "o": "人",
                "p": "心",
                "q": "手",
                "r": "口",
                "s": "尸",
                "t": "廿",
                "u": "山",
                "v": "女",
                "w": "田",
                "x": "難",
                "y": "卜",
                "z": "重"
        ]
}
