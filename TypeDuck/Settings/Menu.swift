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

                let settingsTitle: String = NSLocalizedString(Constant.menuSettingsTitleKey, comment: "")
                let settings = NSMenuItem(title: settingsTitle, action: #selector(openSettings), keyEquivalent: ",")
                settings.keyEquivalentModifierMask = [.control, .shift]
                menu.addItem(settings)

                // TODO: - Check for Updates
                /*
                let check4updatesTitle: String = NSLocalizedString(Constant.menuCheck4UpdatesTitleKey, comment: "")
                let check4updates = NSMenuItem(title: check4updatesTitle, action: #selector(openSettings), keyEquivalent: "")
                menu.addItem(check4updates)
                */

                let helpTitle: String = NSLocalizedString(Constant.menuHelpTitleKey, comment: "")
                let help = NSMenuItem(title: helpTitle, action: #selector(openHelp), keyEquivalent: "")
                menu.addItem(help)

                let aboutTitle: String = NSLocalizedString(Constant.menuAboutTitleKey, comment: "")
                let about = NSMenuItem(title: aboutTitle, action: #selector(openAbout), keyEquivalent: "")
                menu.addItem(about)

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


        @objc private func openSettings() {
                AppSettings.updateSelectedSettingsSidebarRow(to: .candidates)
                displaySettingsWindow()
        }
        @objc private func openHelp() {
                AppSettings.updateSelectedSettingsSidebarRow(to: .help)
                displaySettingsWindow()
        }
        @objc private func openAbout() {
                AppSettings.updateSelectedSettingsSidebarRow(to: .about)
                displaySettingsWindow()
        }
        private func displaySettingsWindow() {
                let windowIdentifiers: [String] = NSApp.windows.map(\.identifier?.rawValue).compactMap({ $0 })
                let shouldOpenNewWindow: Bool = !(windowIdentifiers.contains(Constant.TypeDuckSettingsWindowIdentifier))
                guard shouldOpenNewWindow else { return }
                let frame: CGRect = settingsWindowFrame()
                let window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: true)
                window.identifier = NSUserInterfaceItemIdentifier(rawValue: Constant.TypeDuckSettingsWindowIdentifier)
                window.title = NSLocalizedString(Constant.settingsWindowTitleKey, comment: "")
                let visualEffectView = NSVisualEffectView()
                visualEffectView.material = .sidebar
                visualEffectView.blendingMode = .behindWindow
                visualEffectView.state = .active
                window.contentView = visualEffectView
                let hostingController = NSHostingController(rootView: SettingsView())
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
        private func settingsWindowFrame() -> CGRect {
                let screenWidth: CGFloat = NSScreen.main?.frame.size.width ?? 1920
                let screenHeight: CGFloat = NSScreen.main?.frame.size.height ?? 1080
                let x: CGFloat = screenWidth / 4.0
                let y: CGFloat = screenHeight / 5.0
                let width: CGFloat = screenWidth / 2.0
                let height: CGFloat = (screenHeight / 5.0) * 3.0
                return CGRect(x: x, y: y, width: width, height: height)
        }
}
