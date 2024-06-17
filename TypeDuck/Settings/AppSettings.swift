import Foundation
import CoreIME

struct AppSettings {

        /// Translations
        static let commentLanguages: [Language] = [.English, .Hindi, .Indonesian, .Nepali, .Urdu ]

        private static let defaultEnabledCommentLanguages: [Language] = commentLanguages

        /// Translations
        private(set) static var enabledCommentLanguages: [Language] = {
                guard let savedValue = UserDefaults.standard.string(forKey: SettingsKey.EnabledCommentLanguages) else { return defaultEnabledCommentLanguages }
                let languageValues: [String] = savedValue.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }).filter({ !$0.isEmpty })
                guard languageValues.isNotEmpty else { return [] }
                let languages: [Language] = languageValues.compactMap({ Language.language(of: $0) }).uniqued()
                return commentLanguages.filter({ languages.contains($0) })
        }()
        static func updateCommentLanguage(_ language: Language, shouldEnable: Bool) {
                let newLanguages: [Language] = enabledCommentLanguages + [language]
                let handledNewLanguages: [Language] = newLanguages.compactMap({ item -> Language? in
                        guard item == language else { return item }
                        guard shouldEnable else { return nil }
                        return item
                })
                enabledCommentLanguages = handledNewLanguages.uniqued()
                let newText: String = enabledCommentLanguages.map(\.name).joined(separator: ",")
                UserDefaults.standard.set(newText, forKey: SettingsKey.EnabledCommentLanguages)
        }

        private(set) static var primaryCommentLanguage: Language = {
                guard let savedValue = UserDefaults.standard.string(forKey: SettingsKey.PrimaryCommentLanguage) else { return .English }
                let name: String = savedValue.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .controlCharacters)
                guard let language = Language.language(of: name) else { return .English }
                return language
        }()
        static func updatePrimaryCommentLanguage(to language: Language) {
                primaryCommentLanguage = language
                let value: String = language.name
                UserDefaults.standard.set(value, forKey: SettingsKey.PrimaryCommentLanguage)
        }

        /// Candidate count per page
        private(set) static var candidatePageSize: Int = {
                let savedValue: Int = UserDefaults.standard.integer(forKey: SettingsKey.CandidatePageSize)
                let isSavedValueValid: Bool = pageSizeValidity(of: savedValue)
                guard isSavedValueValid else { return defaultCandidatePageSize }
                return savedValue
        }()
        static func updateCandidatePageSize(to newPageSize: Int) {
                let isNewPageSizeValid: Bool = pageSizeValidity(of: newPageSize)
                guard isNewPageSizeValid else { return }
                candidatePageSize = newPageSize
                UserDefaults.standard.set(newPageSize, forKey: SettingsKey.CandidatePageSize)
        }
        private static func pageSizeValidity(of value: Int) -> Bool {
                return candidatePageSizeRange.contains(value)
        }
        private static let defaultCandidatePageSize: Int = 7
        static let candidatePageSizeRange: Range<Int> = 1..<11

        private(set) static var cangjieVariant: CangjieVariant = {
                let savedValue: Int = UserDefaults.standard.integer(forKey: SettingsKey.CangjieVariant)
                switch savedValue {
                case CangjieVariant.cangjie5.rawValue:
                        return .cangjie5
                case CangjieVariant.cangjie3.rawValue:
                        return .cangjie3
                case CangjieVariant.quick5.rawValue:
                        return .quick5
                case CangjieVariant.quick3.rawValue:
                        return .quick3
                default:
                        return .cangjie5
                }
        }()
        static func updateCangjieVariant(to variant: CangjieVariant) {
                cangjieVariant = variant
                let value: Int = variant.rawValue
                UserDefaults.standard.set(value, forKey: SettingsKey.CangjieVariant)
        }

        private(set) static var isInputMemoryOn: Bool = {
                let savedValue: Int = UserDefaults.standard.integer(forKey: SettingsKey.UserLexiconInputMemory)
                switch savedValue {
                case 0, 1:
                        return true
                case 2:
                        return false
                default:
                        return true
                }
        }()
        static func updateInputMemory(to isOn: Bool) {
                isInputMemoryOn = isOn
                let value: Int = isOn ? 1 : 2
                UserDefaults.standard.set(value, forKey: SettingsKey.UserLexiconInputMemory)
        }

        /// Example: 1.0.1 (23)
        static let version: String = {
                let marketingVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "version_not_found"
                let currentProjectVersion: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "build_not_found"
                return marketingVersion + " (" + currentProjectVersion + ")"
        }()

        /// Settings Window
        private(set) static var selectedSettingsSidebarRow: SettingsSidebarRow = .general
        static func updateSelectedSettingsSidebarRow(to row: SettingsSidebarRow) {
                selectedSettingsSidebarRow = row
        }

        static let TypeDuckSettingsWindowIdentifier: String = "TypeDuckSettingsWindowIdentifier"
}

struct SettingsKey {
        static let CandidatePageSize: String = "CandidatePageSize"
        static let EnabledCommentLanguages: String = "EnabledCommentLanguages"
        static let PrimaryCommentLanguage: String = "PrimaryCommentLanguage"
        static let CangjieVariant: String = "CangjieVariant"
        static let UserLexiconInputMemory: String = "UserLexiconInputMemory"
}

extension Language {
        var isEnabledCommentLanguage: Bool {
                return AppSettings.enabledCommentLanguages.contains(self)
        }
        var isPrimaryCommentLanguage: Bool {
                return self == AppSettings.primaryCommentLanguage
        }
}
