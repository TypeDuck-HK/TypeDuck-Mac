enum Language: String, Hashable, Identifiable, CaseIterable {

        /// 粵語
        case Cantonese

        /// 英語
        case English

        /// 印地語
        case Hindi

        /// 印尼語
        case Indonesian

        /// 尼泊爾語
        case Nepali

        /// 烏爾都語. RTL
        case Urdu

        /// English & Indonesian
        var isLatin: Bool {
                switch self {
                case .English, .Indonesian:
                        return true
                default:
                        return false
                }
        }

        /// Hindi & Nepali
        var isDevanagari: Bool {
                switch self {
                case .Hindi, .Nepali:
                        return true
                default:
                        return false
                }
        }

        /// Urdu
        var isRTL: Bool {
                return self == .Urdu
        }

        /// Identifiable
        var id: String {
                return rawValue
        }
}
