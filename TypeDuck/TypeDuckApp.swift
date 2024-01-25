import AppKit
import InputMethodKit

final class PrincipalApplication: NSApplication {

        private let appDelegate = AppDelegate()

        override init() {
                super.init()
                self.delegate = appDelegate
        }

        required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
        }
}

@main
final class AppDelegate: NSObject, NSApplicationDelegate {

        static var server: IMKServer? = nil

        func applicationDidFinishLaunching(_ notification: Notification) {
                handleCommandLineArguments()
                let name: String = (Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String) ?? "hk_eduhk_inputmethod_TypeDuck_Connection"
                let identifier: String = Bundle.main.bundleIdentifier ?? "hk.eduhk.inputmethod.TypeDuck"
                Self.server = IMKServer(name: name, bundleIdentifier: identifier)
        }

        private func handleCommandLineArguments() {
                let shouldInstall: Bool = CommandLine.arguments.contains("install")
                guard shouldInstall else { return }
                register()
                activate()
                NSRunningApplication.current.terminate()
                NSApp.terminate(self)
                exit(0)
        }
        private func register() {
                let url = Bundle.main.bundleURL
                let cfUrl = url as CFURL
                TISRegisterInputSource(cfUrl)
        }
        private func activate() {
                let kInputSourceID: String = "hk.eduhk.inputmethod.TypeDuck"
                let kInputModeID: String = "hk.eduhk.inputmethod.TypeDuck.IM"
                guard let inputSourceList = TISCreateInputSourceList(nil, true).takeRetainedValue() as? [TISInputSource] else { return }
                for inputSource in inputSourceList {
                        guard let pointer = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) else { return }
                        let inputSourceID = Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
                        guard inputSourceID == kInputSourceID || inputSourceID == kInputModeID else { return }
                        TISEnableInputSource(inputSource)
                        TISSelectInputSource(inputSource)
                }
        }
}
