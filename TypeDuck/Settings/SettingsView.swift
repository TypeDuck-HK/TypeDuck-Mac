import SwiftUI

final class SettingsViewAppDelegate: NSObject, NSApplicationDelegate {
        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
                return true
        }
        func applicationWillFinishLaunching(_ notification: Notification) {
                NSWindow.allowsAutomaticWindowTabbing = false
        }
        func applicationDidFinishLaunching(_ notification: Notification) {
                _ = NSApp.windows.map({ $0.tabbingMode = .disallowed })
        }
}

struct SettingsView: View {

        @NSApplicationDelegateAdaptor(SettingsViewAppDelegate.self) var appDelegate

        // macOS 13.0+
        @State private var selection: SettingsSidebarRow = AppSettings.selectedSettingsSidebarRow

        // macOS 12
        @State private var isCandidatesViewActive: Bool = AppSettings.selectedSettingsSidebarRow == .candidates
        @State private var isHelpViewActive: Bool = AppSettings.selectedSettingsSidebarRow == .help
        @State private var isAboutViewActive: Bool = AppSettings.selectedSettingsSidebarRow == .about

        var body: some View {
                if #available(macOS 13.0, *) {
                        NavigationSplitView {
                                List(selection: $selection) {
                                        Label("SettingsView.NavigationTitle.Settings", systemImage: "gear").tag(SettingsSidebarRow.candidates)
                                        Label("SettingsView.NavigationTitle.Help", systemImage: "keyboard").tag(SettingsSidebarRow.help)
                                        Label("SettingsView.NavigationTitle.About", systemImage: "info.circle").tag(SettingsSidebarRow.about)
                                }
                                .toolbarBackground(Material.bar, for: .windowToolbar)
                                .navigationTitle("SettingsView.NavigationTitle.Settings")
                        } detail: {
                                switch selection {
                                case .candidates:
                                        CandidatesView().applyVisualEffect()
                                case .help:
                                        HelpView().applyVisualEffect()
                                case .about:
                                        AboutView().applyVisualEffect()
                                }
                        }
                } else {
                        NavigationView {
                                List {
                                        NavigationLink(destination: CandidatesView().applyVisualEffect(), isActive: $isCandidatesViewActive) {
                                                Label("SettingsView.NavigationTitle.Settings", systemImage: "gear")
                                        }
                                        NavigationLink(destination: HelpView().applyVisualEffect(), isActive: $isHelpViewActive) {
                                                Label("SettingsView.NavigationTitle.Help", systemImage: "keyboard")
                                        }
                                        NavigationLink(destination: AboutView().applyVisualEffect(), isActive: $isAboutViewActive) {
                                                Label("SettingsView.NavigationTitle.About", systemImage: "info.circle")
                                        }
                                }
                                .listStyle(.sidebar)
                                .navigationTitle("SettingsView.NavigationTitle.Settings")
                        }
                }
        }
}

#Preview {
        SettingsView()
}

enum SettingsSidebarRow: Int, Hashable, Identifiable, CaseIterable {
        case candidates
        case help
        case about
        var id: Int {
                return rawValue
        }
}
