import Foundation

struct AppSettings {

        static let commentLanguages: [Language] = [.English, .Hindi, .Indonesian, .Nepali, .Urdu ]

        private static let defaultEnabledCommentLanguages: [Language] = commentLanguages

        private(set) static var enabledCommentLanguages: [Language] = {
                guard let savedValue = UserDefaults.standard.string(forKey: SettingsKey.EnabledCommentLanguages) else { return defaultEnabledCommentLanguages }
                let languageValues: [String] = savedValue.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }).filter({ !$0.isEmpty })
                guard !(languageValues.isEmpty) else { return [] }
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
        static func updatePrimaryCommentLanguage(to languageName: String) {
                guard let language = Language.language(of: languageName) else { return }
                primaryCommentLanguage = language
                let value: String = language.name
                UserDefaults.standard.set(value, forKey: SettingsKey.PrimaryCommentLanguage)
        }


        /// Settings Window
        private(set) static var selectedSettingsSidebarRow: SettingsSidebarRow = .general
        static func updateSelectedSettingsSidebarRow(to row: SettingsSidebarRow) {
                selectedSettingsSidebarRow = row
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
        }
        private static func pageSizeValidity(of value: Int) -> Bool {
                return candidatePageSizeRange.contains(value)
        }
        private static let defaultCandidatePageSize: Int = 7
        static let candidatePageSizeRange: Range<Int> = 1..<11


        /// Example: 1.0.1 (23)
        static let version: String = {
                let marketingVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "version_not_found"
                let currentProjectVersion: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "build_not_found"
                return marketingVersion + " (" + currentProjectVersion + ")"
        }()

        static let TypeDuckSettingsWindowIdentifier: String = "TypeDuckSettingsWindowIdentifier"
}

struct SettingsKey {
        static let CandidatePageSize: String = "CandidatePageSize"
        static let EnabledCommentLanguages: String = "EnabledCommentLanguages"
        static let PrimaryCommentLanguage: String = "PrimaryCommentLanguage"
}

extension Language {
        var isEnabledCommentLanguage: Bool {
                return AppSettings.enabledCommentLanguages.contains(self)
        }
        var isPrimaryCommentLanguage: Bool {
                return self == AppSettings.primaryCommentLanguage
        }
}
