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
                                                        Text("SettingsView.Colon").foregroundStyle(Color.secondary)
                                                        Text(verbatim: "1, 2, 3, …, 8, 9, 0")
                                                        Spacer()
                                                }
                                                .font(.subheadline)
                                        }
                                }
                                .block()
                                VStack(spacing: 8) {
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.ClearCurrentPreEditText")
                                                Text.separator
                                                KeyBlockView.escape
                                                Text.or
                                                KeyBlockView.control
                                                Text.plus
                                                KeyBlockView.shift
                                                Text.plus
                                                KeyBlockView("U")
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.InputCurrentPreEditText")
                                                Text.separator
                                                KeyBlockView.returnKey
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.InputCurrentRomanization")
                                                Text.separator
                                                KeyBlockView.shift
                                                Text.plus
                                                KeyBlockView.returnKey
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.SelectCandidate")
                                                Text.separator
                                                KeyBlockView.space
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.SelectFirstCharacterOfCandidate")
                                                Text.separator
                                                KeyBlockView("[")
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.SelectLastCharacterOfCandidate")
                                                Text.separator
                                                KeyBlockView("]")
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("SettingsView.HelpView.Shortcut.ForgetCandidate")
                                                Text.separator
                                                KeyBlockView.control
                                                Text.plus
                                                KeyBlockView.shift
                                                Text.plus
                                                KeyBlockView.backwardDelete
                                                Spacer()
                                        }
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
                        .padding(.horizontal, 2)
                        .frame(width: 80, height: 24)
                        .background(Material.regular, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        }

        static let control: KeyBlockView = KeyBlockView("Control ⌃")
        static let shift: KeyBlockView = KeyBlockView("Shift ⇧")
        static let number: KeyBlockView = KeyBlockView(localized: "SettingsView.HelpView.Shortcut.ToggleOption.NumberKeys")
        static let space: KeyBlockView = KeyBlockView("Space ␣")
        static let escape: KeyBlockView = KeyBlockView("esc ⎋")
        static let tab: KeyBlockView = KeyBlockView("Tab ⇥")
        static let returnKey: KeyBlockView = KeyBlockView("Return ⏎")

        /// Backspace. NOT Forward-Delete.
        static let backwardDelete: KeyBlockView = KeyBlockView("Delete ⌫")
}

private extension Text {
        static let separator: Text = Text("SettingsView.Colon").foregroundColor(.secondary)
        static let plus: Text = Text(verbatim: "＋")
        static let or: Text = Text("SettingsView.HelpView.Disjunction")
}
