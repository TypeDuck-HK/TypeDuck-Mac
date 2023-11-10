import SwiftUI
import InputMethodKit

extension TypeDuckInputController {

        override func menu() -> NSMenu! {
                let menuTitle: String = NSLocalizedString(Constant.menuTitleKey, comment: "")
                let menu = NSMenu(title: menuTitle)

                for language in AppSettings.commentLanguages {
                        let selector: Selector? = {
                                switch language {
                                case .Cantonese:
                                        return nil
                                case .English:
                                        return #selector(toggleEnglish)
                                case .Hindi:
                                        return #selector(toggleHindi)
                                case .Indonesian:
                                        return #selector(toggleIndonesian)
                                case .Nepali:
                                        return #selector(toggleNepali)
                                case .Urdu:
                                        return #selector(toggleUrdu)
                                case .Unicode:
                                        return nil
                                }
                        }()
                        let name: String = language.name
                        let localizedName: String = NSLocalizedString(name, comment: "")
                        let item: NSMenuItem = NSMenuItem(title: localizedName, action: selector, keyEquivalent: "")
                        item.state = language.isEnabledCommentLanguage ? .on : .off
                        menu.addItem(item)
                }

                menu.addItem(.separator())

                let helpTitle: String = NSLocalizedString(Constant.menuHelpTitleKey, comment: "")
                let help = NSMenuItem(title: helpTitle, action: #selector(openHelpWindow), keyEquivalent: "")
                menu.addItem(help)

                let terminateTitle: String = NSLocalizedString(Constant.menuTerminateTitleKey, comment: "")
                let terminate = NSMenuItem(title: terminateTitle, action: #selector(terminateApp), keyEquivalent: "")
                menu.addItem(terminate)

                return menu
        }

        @objc private func toggleEnglish() {
                let language: Language = .English
                let isEnabled: Bool = language.isEnabledCommentLanguage
                let shouldEnable: Bool = !isEnabled
                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
        }
        @objc private func toggleHindi() {
                let language: Language = .Hindi
                let isEnabled: Bool = language.isEnabledCommentLanguage
                let shouldEnable: Bool = !isEnabled
                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
        }
        @objc private func toggleIndonesian() {
                let language: Language = .Indonesian
                let isEnabled: Bool = language.isEnabledCommentLanguage
                let shouldEnable: Bool = !isEnabled
                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
        }
        @objc private func toggleNepali() {
                let language: Language = .Nepali
                let isEnabled: Bool = language.isEnabledCommentLanguage
                let shouldEnable: Bool = !isEnabled
                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
        }
        @objc private func toggleUrdu() {
                let language: Language = .Urdu
                let isEnabled: Bool = language.isEnabledCommentLanguage
                let shouldEnable: Bool = !isEnabled
                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
        }

        @objc private func openHelpWindow() {
                let shouldOpenNewWindow: Bool = NSApp.windows.filter({ $0.identifier?.rawValue == Constant.preferencesWindowIdentifier }).isEmpty
                guard shouldOpenNewWindow else { return }
                let frame: CGRect = helpWindowFrame()
                let window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: true)
                window.identifier = NSUserInterfaceItemIdentifier(rawValue: Constant.preferencesWindowIdentifier)
                window.title = NSLocalizedString(Constant.preferencesWindowTitleKey, comment: "")
                let visualEffectView = NSVisualEffectView()
                visualEffectView.material = .sidebar
                visualEffectView.blendingMode = .behindWindow
                visualEffectView.state = .active
                window.contentView = visualEffectView
                let hostingController = NSHostingController(rootView: HelpView())
                window.contentView?.addSubview(hostingController.view)
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                if let topAnchor = window.contentView?.topAnchor,
                   let bottomAnchor = window.contentView?.bottomAnchor,
                   let leadingAnchor = window.contentView?.leadingAnchor,
                   let trailingAnchor = window.contentView?.trailingAnchor {
                        NSLayoutConstraint.activate([
                                hostingController.view.topAnchor.constraint(equalTo: topAnchor),
                                hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
                                hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                                hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor)
                        ])
                }
                window.contentViewController?.addChild(hostingController)
                window.orderFrontRegardless()
                window.setFrame(frame, display: true)
                NSApp.activate(ignoringOtherApps: true)
        }
        private func helpWindowFrame() -> CGRect {
                let screenWidth: CGFloat = NSScreen.main?.frame.size.width ?? 1920
                let screenHeight: CGFloat = NSScreen.main?.frame.size.height ?? 1080
                let x: CGFloat = screenWidth / 4.0
                let y: CGFloat = screenHeight / 5.0
                let width: CGFloat = screenWidth / 2.0
                let height: CGFloat = (screenHeight / 5.0) * 3.0
                return CGRect(x: x, y: y, width: width, height: height)
        }

        @objc private func terminateApp() {
                switchInputSource()
                NSRunningApplication.current.terminate()
                NSApp.terminate(self)
                exit(0)
        }
        private func switchInputSource() {
                guard let inputSourceList = TISCreateInputSourceList(nil, true).takeRetainedValue() as? [TISInputSource] else { return }
                for inputSource in inputSourceList {
                        if shouldSelect(inputSource) {
                                TISSelectInputSource(inputSource)
                                break
                        }
                }
        }
        private func shouldSelect(_ inputSource: TISInputSource) -> Bool {
                guard let pointer2ID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) else { return false }
                let inputSourceID = Unmanaged<CFString>.fromOpaque(pointer2ID).takeUnretainedValue() as String
                guard inputSourceID.hasPrefix("com.apple.keylayout") else { return false }
                guard let pointer2IsSelectable = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsSelectCapable) else { return false }
                let isSelectable = Unmanaged<CFBoolean>.fromOpaque(pointer2IsSelectable).takeRetainedValue()
                return CFBooleanGetValue(isSelectable)
        }
}

struct Constant {
        static let menuTitleKey: String = "menu.title"
        static let menuHelpTitleKey: String = "menu.help"
        static let menuTerminateTitleKey: String = "menu.terminate"

        static let preferencesWindowTitleKey: String = "Preferences.Window.Title"

        static let preferencesWindowIdentifier: String = "TypeDuckPreferencesWindowIdentifier"
}

struct SettingsKey {
        static let EnabledCommentLanguages: String = "EnabledCommentLanguages"
}

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

        /// Candidate page size
        static let pageSize: Int = 9

        /// Example: 1.0.1 (23)
        static let version: String = {
                let marketingVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.1.0"
                let currentProjectVersion: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
                return marketingVersion + " (" + currentProjectVersion + ")"
        }()
}

extension Language {
        var isEnabledCommentLanguage: Bool {
                return AppSettings.enabledCommentLanguages.contains(self)
        }
}
