import AppKit
import InputMethodKit
import os.log

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

        static let shared: AppDelegate = AppDelegate()

        private override init() {
                super.init()
        }

        private lazy var imkServer: IMKServer? = nil

        func applicationDidFinishLaunching(_ notification: Notification) {
                let name: String = (Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String) ?? "hk.eduhk.inputmethod.TypeDuck_Connection"
                let identifier: String = Bundle.main.bundleIdentifier ?? "hk.eduhk.inputmethod.TypeDuck"
                imkServer = IMKServer(name: name, bundleIdentifier: identifier)
        }
}

extension CommandLine {
        static func handleArguments() {
                let shouldInstall: Bool = CommandLine.arguments.contains("install")
                guard shouldInstall else { return }
                register()
                activate()
                NSRunningApplication.current.terminate()
                exit(0)
        }
        private static func register() {
                let path = "/Library/Input Methods/TypeDuck.app"
                let url = FileManager.default.fileExists(atPath: path) ? URL(fileURLWithPath: path) : Bundle.main.bundleURL
                TISRegisterInputSource(url as CFURL)
        }
        private static func activate() {
                let kInputSourceID: String = "hk.eduhk.inputmethod.TypeDuck"
                let kInputModeID: String = "hk.eduhk.inputmethod.TypeDuck.TypeDuckIM"
                guard let inputSourceList = TISCreateInputSourceList(nil, true).takeRetainedValue() as? [TISInputSource] else { return }
                for inputSource in inputSourceList {
                        guard let pointer = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) else { continue }
                        let inputSourceID = Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
                        guard inputSourceID == kInputSourceID || inputSourceID == kInputModeID else { continue }
                        TISEnableInputSource(inputSource)
                        TISSelectInputSource(inputSource)
                }
        }
}

extension Logger {
        static let shared: Logger = Logger(subsystem: "hk.eduhk.inputmethod.TypeDuck", category: "inputmethod")
}
