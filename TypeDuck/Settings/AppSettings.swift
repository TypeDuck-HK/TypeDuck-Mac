import Foundation

struct AppSettings {

        static let commentLanguages: [Language] = [.English, .Hindi, .Indonesian, .Nepali, .Urdu ]

        private static let defaultEnabledCommentLanguages: [Language] = commentLanguages

        private(set) static var enabledCommentLanguages: [Language] = {
                guard let savedValue = UserDefaults.standard.string(forKey: SettingsKey.EnabledCommentLanguages) else { return defaultEnabledCommentLanguages }
                let languageValues: [String] = savedValue.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }).filter({ !$0.isEmpty })
                guard !(languageValues.isEmpty) else { return [] }
                let languages: [Language] = languageValues.map({ Language.language(of: $0) }).compactMap({ $0 }).uniqued()
                return commentLanguages.filter({ languages.contains($0) })
        }()
        static func updateCommentLanguage(_ language: Language, shouldEnable: Bool) {
                let newLanguages: [Language] = enabledCommentLanguages + [language]
                let handledNewLanguages: [Language?] = newLanguages.map({ item -> Language? in
                        guard item == language else { return item }
                        guard shouldEnable else { return nil }
                        return item
                })
                enabledCommentLanguages = handledNewLanguages.compactMap({ $0 }).uniqued()
                let newText: String = enabledCommentLanguages.map(\.name).joined(separator: ",")
                UserDefaults.standard.set(newText, forKey: SettingsKey.EnabledCommentLanguages)
        }


        /// Settings Window
        private(set) static var selectedSettingsSidebarRow: SettingsSidebarRow = .candidates
        static func updateSelectedSettingsSidebarRow(to row: SettingsSidebarRow) {
                selectedSettingsSidebarRow = row
        }


        private(set) static var candidatePageSize: Int = {
                let savedValue: Int = UserDefaults.standard.integer(forKey: SettingsKey.CandidatePageSize)
                let isSavedValueValid: Bool = pageSizeValidity(of: savedValue)
                guard isSavedValueValid else { return 10 }
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
        static let EnabledCommentLanguages: String = "EnabledCommentLanguages"
        static let CandidatePageSize: String = "CandidatePageSize"
}

extension Language {
        var isEnabledCommentLanguage: Bool {
                return AppSettings.enabledCommentLanguages.contains(self)
        }
}
