import Foundation
import CoreIME

struct Options {

        /// 字形標準
        private(set) static var characterStandard: CharacterStandard = {
                let savedValue: Int = UserDefaults.standard.integer(forKey: OptionsKey.CharacterStandard)
                switch savedValue {
                case 0, 1, 2, 3:
                        return .traditional
                case 4:
                        return .simplified
                default:
                        return .traditional
                }
        }()
        static func updateCharacterStandard(to standard: CharacterStandard) {
                characterStandard = standard
                let value: Int = standard.rawValue
                UserDefaults.standard.set(value, forKey: OptionsKey.CharacterStandard)
        }

        /// 半形／全形數字、字母
        private(set) static var characterForm: CharacterForm = {
                let savedValue: Int = UserDefaults.standard.integer(forKey: OptionsKey.CharacterForm)
                switch savedValue {
                case 0, 1:
                        return .halfWidth
                case 2:
                        return .fullWidth
                default:
                        return .halfWidth
                }
        }()
        static func updateCharacterForm(to form: CharacterForm) {
                characterForm = form
                let value: Int = form.rawValue
                UserDefaults.standard.set(value, forKey: OptionsKey.CharacterForm)
        }

        /// 標點符號形態. 中文／英文標點
        private(set) static var punctuationForm: PunctuationForm = {
                let savedValue: Int = UserDefaults.standard.integer(forKey: OptionsKey.PunctuationForm)
                switch savedValue {
                case 0, 1:
                        return .cantonese
                case 2:
                        return .english
                default:
                        return .cantonese
                }
        }()
        static func updatePunctuationForm(to form: PunctuationForm) {
                punctuationForm = form
                let value: Int = form.rawValue
                UserDefaults.standard.set(value, forKey: OptionsKey.PunctuationForm)
        }

        /// 候選詞包含 Emoji
        private(set) static var isEmojiSuggestionsOn: Bool = {
                let savedValue: Int = UserDefaults.standard.integer(forKey: OptionsKey.EmojiSuggestions)
                switch savedValue {
                case 0, 1:
                        return false
                case 2:
                        return true
                default:
                        return false
                }
        }()
        static func updateEmojiSuggestions(to isOn: Bool) {
                isEmojiSuggestionsOn = isOn
                let value: Int = isOn ? 2 : 1
                UserDefaults.standard.set(value, forKey: OptionsKey.EmojiSuggestions)
        }

        /// 輸入法模式. Cantonese / ABC
        private(set) static var inputMethodMode: InputMethodMode = {
                let savedValue: Int = UserDefaults.standard.integer(forKey: OptionsKey.InputMethodMode)
                switch savedValue {
                case 0, 1:
                        return .cantonese
                case 2:
                        return .abc
                default:
                        return .cantonese
                }
        }()
        static func updateInputMethodMode(to mode: InputMethodMode) {
                inputMethodMode = mode
                let value: Int = mode.rawValue
                UserDefaults.standard.set(value, forKey: OptionsKey.InputMethodMode)
        }
}

private struct OptionsKey {
        static let CharacterStandard: String = "CharacterStandard"
        static let CharacterForm: String = "CharacterForm"
        static let PunctuationForm: String = "PunctuationForm"
        static let EmojiSuggestions: String = "EmojiSuggestions"

        static let InputMethodMode: String = "InputMethodMode"
}

/// 半形／全形數字、字母
enum CharacterForm: Int {
        case halfWidth = 1
        case fullWidth = 2
}

/// 標點符號形態
enum PunctuationForm: Int {
        case cantonese = 1
        case english = 2
        var isCantoneseMode: Bool {
                return self == .cantonese
        }
}

/// Cantonese / ABC
enum InputMethodMode: Int {
        case cantonese = 1
        case abc = 2
        var isCantonese: Bool {
                return self == .cantonese
        }
        var isABC: Bool {
                return self == .abc
        }
}
