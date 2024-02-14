import SwiftUI

struct HelpView: View {
        var body: some View {
                ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 4) {
                                        LabelText("SettingsView.HelpView.Shortcut.ToggleOptionsView")
                                        Text.separator
                                        KeyBlockView.control
                                        Text.plus
                                        KeyBlockView.shift
                                        Text.plus
                                        KeyBlockView("`")
                                        Spacer()
                                }
                                .block()
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        LabelText("SettingsView.HelpView.Shortcut.ToggleOption")
                                        Text.separator
                                        VStack(spacing: 6) {
                                                HStack(spacing: 4) {
                                                        KeyBlockView.control
                                                        Text.plus
                                                        KeyBlockView.shift
                                                        Text.plus
                                                        KeyBlockView.number
                                                        Spacer()
                                                }
                                                HStack(spacing: 0) {
                                                        Text("SettingsView.HelpView.Shortcut.ToggleOption.NumberKeys").fontWeight(.medium)
                                                        Text("SettingsView.Colon").foregroundColor(.secondary)
                                                        Text(verbatim: "1, 2, 3, …, 8, 9, 0")
                                                        Spacer()
                                                }
                                                .font(.subheadline)
                                        }
                                }
                                .block()
                                HStack(spacing: 4) {
                                        LabelText("SettingsView.HelpView.Shortcut.RemoveCandidate")
                                        Text.separator
                                        KeyBlockView.control
                                        Text.plus
                                        KeyBlockView.shift
                                        Text.plus
                                        KeyBlockView.backwardDelete
                                        Spacer()
                                }
                                .block()
                                HStack(spacing: 4) {
                                        LabelText("SettingsView.HelpView.Shortcut.ClearInput")
                                        Text.separator
                                        KeyBlockView.escape
                                        Spacer()
                                }
                                .block()
                                VStack(spacing: 8) {
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.PrevCandidate")
                                                Text.separator
                                                KeyBlockView("▲")
                                                Text.or
                                                KeyBlockView.shift
                                                Text.plus
                                                KeyBlockView.tab
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.NextCandidate")
                                                Text.separator
                                                KeyBlockView("▼")
                                                Text.or
                                                KeyBlockView.tab
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.PrevPage")
                                                Text.separator
                                                KeyBlockView("◀")
                                                Text.or
                                                KeyBlockView("-")
                                                Text.or
                                                KeyBlockView("Page Up ↑")
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.NextPage")
                                                Text.separator
                                                KeyBlockView("▶")
                                                Text.or
                                                KeyBlockView("=")
                                                Text.or
                                                KeyBlockView("Page Down ↓")
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.FirstPage")
                                                Text.separator
                                                KeyBlockView("Home ⤒")
                                                Spacer()
                                        }
                                }
                                .block()
                        }
                        .textSelection(.enabled)
                        .padding()
                }
                .navigationTitle("SettingsView.HelpView.Title")
        }
}

#Preview {
        HelpView()
}

private struct LabelText: View {
        init(_ title: LocalizedStringKey) {
                self.title = title
        }
        private let title: LocalizedStringKey
        var body: some View {
                Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(width: 250, alignment: .leading)
        }
}

private struct KeyBlockView: View {

        init(_ keyText: String) {
                self.keyText = keyText
                self.key = nil
        }

        init(localized key: LocalizedStringKey) {
                self.keyText = nil
                self.key = key
        }

        private let keyText: String?
        private let key: LocalizedStringKey?

        var body: some View {
                let text: Text
                if let key = key {
                    text = Text(key)
                } else {
                    text = Text(verbatim: keyText!)
                }
                return text
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .frame(width: 84, height: 24)
                        .padding(.horizontal, 4)
                        .background(Material.regular, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        }

        static let control: KeyBlockView = KeyBlockView("Control ⌃")
        static let shift: KeyBlockView = KeyBlockView("Shift ⇧")
        static let number: KeyBlockView = KeyBlockView(localized: "SettingsView.HelpView.Shortcut.ToggleOption.NumberKeys")
        static let space: KeyBlockView = KeyBlockView("Space ␣")
        static let escape: KeyBlockView = KeyBlockView("Esc ⎋")
        static let tab: KeyBlockView = KeyBlockView("Tab ⇥")

        /// Backspace. NOT Forward-Delete.
        static let backwardDelete: KeyBlockView = KeyBlockView("Delete ⌫")
}

private extension Text {
        static let separator: Text = Text("SettingsView.Colon").foregroundColor(.secondary)
        static let plus: Text = Text(verbatim: "＋")
        static let or: Text = Text("SettingsView.HelpView.Disjunction")
}


extension View {
        func block() -> some View {
                return self.padding().background(Color.textBackgroundColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
}
extension Color {
        static let textBackgroundColor: Color = Color(nsColor: NSColor.textBackgroundColor)
}
