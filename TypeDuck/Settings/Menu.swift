import SwiftUI
import InputMethodKit

extension TypeDuckInputController {

        override func menu() -> NSMenu! {
                let menuTitle: String = String(localized: "Menu.Title")
                let menu = NSMenu(title: menuTitle)

                let settingsTitle: String = String(localized: "Menu.Settings")
                let settings = NSMenuItem(title: settingsTitle, action: #selector(openSettings), keyEquivalent: ",")
                settings.keyEquivalentModifierMask = [.control, .shift]
                menu.addItem(settings)

                // TODO: - Check for Updates
                let checkForUpdatesTitle: String = String(localized: "Menu.CheckForUpdates")
                _ = NSMenuItem(title: checkForUpdatesTitle, action: #selector(openSettings), keyEquivalent: "")
                // menu.addItem(checkForUpdates)

                let helpTitle: String = String(localized: "Menu.Help")
                let help = NSMenuItem(title: helpTitle, action: #selector(openHelp), keyEquivalent: "")
                menu.addItem(help)

                let aboutTitle: String = String(localized: "Menu.About")
                let about = NSMenuItem(title: aboutTitle, action: #selector(openAbout), keyEquivalent: "")
                menu.addItem(about)

                return menu
        }

        @objc private func openSettings() {
                AppSettings.updateSelectedSettingsSidebarRow(to: .general)
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
                DispatchQueue.main.async { [weak self] in
                        self?.prepareSettingsWindow()
                }
        }
        private func prepareSettingsWindow() {
                let windowIdentifiers: [String] = NSApp.windows.compactMap(\.identifier?.rawValue)
                let shouldOpenNewWindow: Bool = windowIdentifiers.notContains(AppSettings.TypeDuckSettingsWindowIdentifier)
                guard shouldOpenNewWindow else { return }
                let frame: CGRect = settingsWindowFrame()
                let window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: true)
                window.identifier = NSUserInterfaceItemIdentifier(rawValue: AppSettings.TypeDuckSettingsWindowIdentifier)
                window.title = String(localized: "Settings.Window.Title")
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
                let screenWidth: CGFloat = NSScreen.main?.visibleFrame.size.width ?? 1920
                let screenHeight: CGFloat = NSScreen.main?.visibleFrame.size.height ?? 1080
                let x: CGFloat = screenWidth / 4.0
                let y: CGFloat = screenHeight / 5.0
                let width: CGFloat = screenWidth / 2.0
                let height: CGFloat = (screenHeight / 5.0) * 3.0
                return CGRect(x: x, y: y, width: width, height: height)
        }
}
