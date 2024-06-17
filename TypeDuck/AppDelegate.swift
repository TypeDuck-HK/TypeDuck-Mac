import AppKit
import InputMethodKit
import CoreIME

@main
final class AppDelegate: NSObject, NSApplicationDelegate {

        private static var server: IMKServer?

        func applicationDidFinishLaunching(_ notification: Notification) {
                handleCommandLineArguments()
                if Self.server == nil {
                        let name: String = (Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String) ?? "hk.eduhk.inputmethod.TypeDuck_Connection"
                        let identifier: String = Bundle.main.bundleIdentifier ?? "hk.eduhk.inputmethod.TypeDuck"
                        Self.server = IMKServer(name: name, bundleIdentifier: identifier)
                }
                UserLexicon.prepare()
                Engine.prepare()
        }

        private func handleCommandLineArguments() {
                let shouldInstall: Bool = CommandLine.arguments.contains("install")
                guard shouldInstall else { return }
                register()
                activate()
                switchToSystemInputSource()
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
                        guard let pointer = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) else { continue }
                        let inputSourceID = Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
                        guard inputSourceID == kInputSourceID || inputSourceID == kInputModeID else { continue }
                        TISEnableInputSource(inputSource)
                        TISSelectInputSource(inputSource)
                }
        }

        private func switchToSystemInputSource() {
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
