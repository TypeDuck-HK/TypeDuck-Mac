import SwiftUI

enum Language: Int, Hashable, Identifiable, CaseIterable {

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

        /// Character code point
        case Unicode

        /// Identifiable
        var id: Int {
                return rawValue
        }

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

        /// Cantonese & Unicode
        var isAnnotation: Bool {
                switch self {
                case .Cantonese, .Unicode:
                        return true
                default:
                        return false
                }
        }

        /// Non-Annotation
        var isTranslation: Bool {
                switch self {
                case .Cantonese, .Unicode:
                        return false
                default:
                        return true
                }
        }
        
        /// Language name in English
        var name: String {
                switch self {
                case .Cantonese:
                        return "Cantonese"
                case .English:
                        return "English"
                case .Hindi:
                        return "Hindi"
                case .Indonesian:
                        return "Indonesian"
                case .Nepali:
                        return "Nepali"
                case .Urdu:
                        return "Urdu"
                case .Unicode:
                        return "Unicode"
                }
        }
        
        /// Get language from the given name
        /// - Parameter name: Name in english
        /// - Returns: A language?
        static func language(of name: String) -> Language? {
                return Language.allCases.first(where: { $0.name == name })
        }

        var font: Font {
                switch self {
                case .Cantonese:
                        return .body
                case .English:
                        return .englishComment
                case .Hindi:
                        return .devanagariComment
                case .Indonesian:
                        return .indonesianComment
                case .Nepali:
                        return .devanagariComment
                case .Urdu:
                        return .urduComment
                case .Unicode:
                        return .body
                }
        }
    
        var padding: EdgeInsets {
                switch self {
                case .Hindi, .Nepali:
                        return EdgeInsets(top: 0, leading: 0, bottom: -7, trailing: 0)
                case .Urdu:
                        return EdgeInsets(top: -3, leading: 0, bottom: -3, trailing: 0)
                default:
                        return EdgeInsets()
                }
        }
}
