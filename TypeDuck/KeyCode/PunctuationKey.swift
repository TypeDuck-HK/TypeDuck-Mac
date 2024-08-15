struct PunctuationKey: Hashable {

        let keyText: String
        let shiftingKeyText: String
        let instantSymbol: String?
        let instantShiftingSymbol: String?
        let symbols: [PunctuationSymbol]
        let shiftingSymbols: [PunctuationSymbol]

        private static let halfWidth: String = "半形"
        private static let fullWidth: String = "全形"
        private static let verticalText: String = "直寫"

        static let comma: PunctuationKey = {
                let shiftingSymbols: [PunctuationSymbol] = [
                        PunctuationSymbol("《"),
                        PunctuationSymbol("〈"),
                        PunctuationSymbol("<", comment: halfWidth),
                        PunctuationSymbol("＜", comment: fullWidth),
                        PunctuationSymbol(",", comment: "半形逗號")
                ]
                return PunctuationKey(keyText: ",", shiftingKeyText: "<", instantSymbol: "，", instantShiftingSymbol: nil, symbols: [.init("，")], shiftingSymbols: shiftingSymbols)
        }()
        static let period: PunctuationKey = {
                let shiftingSymbols: [PunctuationSymbol] = [
                        PunctuationSymbol("》"),
                        PunctuationSymbol("〉"),
                        PunctuationSymbol(">", comment: halfWidth),
                        PunctuationSymbol("＞", comment: fullWidth),
                        PunctuationSymbol("｡", comment: "半形句號"),
                        PunctuationSymbol(".", comment: "英文句點"),
                        PunctuationSymbol("．", comment: "全形英文句點")
                ]
                return PunctuationKey(keyText: ".", shiftingKeyText: ">", instantSymbol: "。", instantShiftingSymbol: nil, symbols: [.init("。")], shiftingSymbols: shiftingSymbols)
        }()
        static let slash: PunctuationKey = {
                let symbols: [PunctuationSymbol] = [
                        PunctuationSymbol("/", comment: halfWidth),
                        PunctuationSymbol("／", comment: fullWidth),
                        PunctuationSymbol("÷"),
                        PunctuationSymbol("≠"),
                        PunctuationSymbol("?", comment: halfWidth),
                        PunctuationSymbol("!", comment: halfWidth),
                        PunctuationSymbol(String.fullWidthSpace, comment: "全形空格")
                ]
                return PunctuationKey(keyText: "/", shiftingKeyText: "?", instantSymbol: nil, instantShiftingSymbol: "？", symbols: symbols, shiftingSymbols: [.init("？")])
        }()
        static let semicolon = PunctuationKey(keyText: ";", shiftingKeyText: ":", instantSymbol: "；", instantShiftingSymbol: "：", symbols: [.init("；")], shiftingSymbols: [.init("：")])
        static let quote: PunctuationKey = {
                let symbols: [PunctuationSymbol] = [
                        PunctuationSymbol("'", comment: halfWidth, secondaryComment: "U+0027"),
                        PunctuationSymbol("＇", comment: fullWidth, secondaryComment: "U+FF07"),
                        PunctuationSymbol("‘", comment: "左", secondaryComment: "U+2018"),
                        PunctuationSymbol("’", comment: "右", secondaryComment: "U+2019"),
                        PunctuationSymbol("`", comment: "重音符", secondaryComment: "U+0060"),
                        PunctuationSymbol("｀", comment: "全形重音符", secondaryComment: "U+FF40")
                ]
                let shiftingSymbols: [PunctuationSymbol] = [
                        PunctuationSymbol("\"", comment: halfWidth, secondaryComment: "U+0022"),
                        PunctuationSymbol("＂", comment: fullWidth, secondaryComment: "U+FF02"),
                        PunctuationSymbol("“", comment: "左", secondaryComment: "U+201C"),
                        PunctuationSymbol("”", comment: "右", secondaryComment: "U+201D"),
                        PunctuationSymbol(";", comment: "半形分號"),
                        PunctuationSymbol(":", comment: "半形冒號")
                ]
                return PunctuationKey(keyText: "'", shiftingKeyText: "\"", instantSymbol: nil, instantShiftingSymbol: nil, symbols: symbols, shiftingSymbols: shiftingSymbols)
        }()
        static let bracketLeft: PunctuationKey = {
                let shiftingSymbols: [PunctuationSymbol] = [
                        PunctuationSymbol("『"),
                        PunctuationSymbol("【"),
                        PunctuationSymbol("〖"),
                        PunctuationSymbol("〔"),
                        PunctuationSymbol("[", comment: halfWidth),
                        PunctuationSymbol("［", comment: fullWidth),
                        PunctuationSymbol("{", comment: halfWidth),
                        PunctuationSymbol("｛", comment: fullWidth),
                        PunctuationSymbol("﹂", comment: verticalText),
                        PunctuationSymbol("﹄", comment: verticalText)
                ]
                return PunctuationKey(keyText: "[", shiftingKeyText: "{", instantSymbol: "「", instantShiftingSymbol: nil, symbols: [.init("「")], shiftingSymbols: shiftingSymbols)
        }()
        static let bracketRight: PunctuationKey = {
                let shiftingSymbols: [PunctuationSymbol] = [
                        PunctuationSymbol("』"),
                        PunctuationSymbol("】"),
                        PunctuationSymbol("〗"),
                        PunctuationSymbol("〕"),
                        PunctuationSymbol("]", comment: halfWidth),
                        PunctuationSymbol("］", comment: fullWidth),
                        PunctuationSymbol("}", comment: halfWidth),
                        PunctuationSymbol("｝", comment: fullWidth),
                        PunctuationSymbol("﹁", comment: verticalText),
                        PunctuationSymbol("﹃", comment: verticalText)
                ]
                return PunctuationKey(keyText: "]", shiftingKeyText: "}", instantSymbol: "」", instantShiftingSymbol: nil, symbols: [.init("」")], shiftingSymbols: shiftingSymbols)
        }()
        static let backSlash: PunctuationKey = {
                let shiftingSymbols: [PunctuationSymbol] = [
                        PunctuationSymbol("|", comment: halfWidth),
                        PunctuationSymbol("｜", comment: fullWidth),
                        PunctuationSymbol("\\", comment: halfWidth),
                        PunctuationSymbol("＼", comment: fullWidth),
                        PunctuationSymbol("､", comment: "半形頓號")
                ]
                return PunctuationKey(keyText: "\\", shiftingKeyText: "|", instantSymbol: "、", instantShiftingSymbol: nil, symbols: [.init("、")], shiftingSymbols: shiftingSymbols)
        }()
        static let backquote: PunctuationKey = {
                let symbols: [PunctuationSymbol] = [
                        PunctuationSymbol("`", comment: "重音符", secondaryComment: "U+0060"),
                        PunctuationSymbol("｀", comment: "全形重音符", secondaryComment: "U+FF40"),
                        PunctuationSymbol("·", comment: "間隔號", secondaryComment: "U+00B7"),
                        PunctuationSymbol("•", comment: "項目符號", secondaryComment: "U+2022"),
                        PunctuationSymbol("‧", comment: "連字點", secondaryComment: "U+2027"),
                        PunctuationSymbol("･", comment: "半形中點", secondaryComment: "U+FF65"),
                        PunctuationSymbol("・", comment: "全形中點", secondaryComment: "U+30FB")
                ]
                let shiftingSymbols: [PunctuationSymbol] = [
                        PunctuationSymbol("~", comment: halfWidth),
                        PunctuationSymbol("～", comment: fullWidth),
                        PunctuationSymbol("≈")
                ]
                return PunctuationKey(keyText: "`", shiftingKeyText: "~", instantSymbol: nil, instantShiftingSymbol: nil, symbols: symbols, shiftingSymbols: shiftingSymbols)
        }()
        static let minus = PunctuationKey(keyText: "-", shiftingKeyText: "_", instantSymbol: "-", instantShiftingSymbol: "——", symbols: [.init("-")], shiftingSymbols: [.init("——")])
        static let equal = PunctuationKey(keyText: "=", shiftingKeyText: "+", instantSymbol: "=", instantShiftingSymbol: "+", symbols: [.init("=")], shiftingSymbols: [.init("+")])
}

struct PunctuationSymbol: Hashable {

        let symbol: String
        let comment: String?
        let secondaryComment: String?

        init(_ symbol: String, comment: String? = nil, secondaryComment: String? = nil) {
                self.symbol = symbol
                self.comment = comment
                self.secondaryComment = secondaryComment
        }
}
