import SwiftUI

struct HelpView: View {
        var body: some View {
                ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                                Text(verbatim: "TypeDuck Shortcuts").font(.title3.bold())
                                VStack(spacing: 8) {
                                        HStack(spacing: 4) {
                                                LabelText("Enter/Exit Options View")
                                                Text.separator
                                                KeyBlockView.control
                                                Text.plus
                                                KeyBlockView.shift
                                                Text.plus
                                                KeyBlockView("`")
                                                Spacer()
                                        }
                                }
                                .block()
                                VStack {
                                        HStack(spacing: 4) {
                                                LabelText("Directly toggle specific option")
                                                Text.separator
                                                KeyBlockView.control
                                                Text.plus
                                                KeyBlockView.shift
                                                Text.plus
                                                KeyBlockView.number
                                                Spacer()
                                        }
                                        HStack {
                                                Text(verbatim: "number: 1, 2, 3, ... 8, 9, 0")
                                                Spacer()
                                        }
                                        .font(.subheadline)
                                }
                                .block()
                                HStack(spacing: 4) {
                                        LabelText("Remove highlighted Candidate from User Lexicon")
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
                                        LabelText("Clear current Input Buffer")
                                        Text.separator
                                        KeyBlockView.escape
                                        Spacer()
                                }
                                .block()
                                VStack(spacing: 8) {
                                        HStack(spacing: 4) {
                                                LabelText("Highlight previous Candidate")
                                                Text.separator
                                                KeyBlockView("⯅")
                                                Text.or
                                                KeyBlockView.shift
                                                Text.plus
                                                KeyBlockView.tab
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("Highlight next Candidate")
                                                Text.separator
                                                KeyBlockView("⯆")
                                                Text.or
                                                KeyBlockView.tab
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("Backward to previous Candidate page")
                                                Text.separator
                                                KeyBlockView("⯇")
                                                Text.or
                                                KeyBlockView("-")
                                                Text.or
                                                KeyBlockView("Page Up ↑")
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("Forward to next Candidate page")
                                                Text.separator
                                                KeyBlockView("⯈")
                                                Text.or
                                                KeyBlockView("=")
                                                Text.or
                                                KeyBlockView("Page Down ↓")
                                                Spacer()
                                        }
                                        HStack(spacing: 4) {
                                                LabelText("Jump to the first Candidate page")
                                                Text.separator
                                                KeyBlockView("Home ⤒")
                                                Spacer()
                                        }
                                }
                                .block()

                                HStack(spacing: 0) {
                                        Spacer()
                                        Text("Version")
                                        Text.separator
                                        Text(verbatim: AppSettings.version)
                                        Spacer()
                                }
                                .padding(.vertical)
                                Text(verbatim: "Welcome to TypeDuck").font(.title3.bold())
                                Text("""
歡迎使用 TypeDuck 打得 - 設有少數族裔語言提示粵拼輸入法！有字想打？一裝即用，毋須再等，即刻打得！
Welcome to TypeDuck: a Cantonese input keyboard with minority language prompts! Got something you want to type? Have your fingers ready, get, set, TYPE DUCK!

如有任何查詢，歡迎電郵至 [info@typeduck.hk](mailto:info@typeduck.hk?subject=Mac%20TypeDuck%20Enquiry%20/%20Issue%20Report%20%7C%20%E6%89%93%E5%BE%97%E7%B2%B5%E8%AA%9E%E8%BC%B8%E5%85%A5%E6%B3%95%E6%9F%A5%E8%A9%A2%EF%BC%8F%E5%95%8F%E9%A1%8C%E5%8C%AF%E5%A0%B1) 或 [lchaakming@eduhk.hk](mailto:lchaakming@eduhk.hk?subject=Mac%20TypeDuck%20Enquiry%20/%20Issue%20Report%20%7C%20%E6%89%93%E5%BE%97%E7%B2%B5%E8%AA%9E%E8%BC%B8%E5%85%A5%E6%B3%95%E6%9F%A5%E8%A9%A2%EF%BC%8F%E5%95%8F%E9%A1%8C%E5%8C%AF%E5%A0%B1)
Should you have any enquiries, please email [info@typeduck.hk](mailto:info@typeduck.hk?subject=Mac%20TypeDuck%20Enquiry%20/%20Issue%20Report%20%7C%20%E6%89%93%E5%BE%97%E7%B2%B5%E8%AA%9E%E8%BC%B8%E5%85%A5%E6%B3%95%E6%9F%A5%E8%A9%A2%EF%BC%8F%E5%95%8F%E9%A1%8C%E5%8C%AF%E5%A0%B1) or [lchaakming@eduhk.hk](mailto:lchaakming@eduhk.hk?subject=Mac%20TypeDuck%20Enquiry%20/%20Issue%20Report%20%7C%20%E6%89%93%E5%BE%97%E7%B2%B5%E8%AA%9E%E8%BC%B8%E5%85%A5%E6%B3%95%E6%9F%A5%E8%A9%A2%EF%BC%8F%E5%95%8F%E9%A1%8C%E5%8C%AF%E5%A0%B1)

本輸入法由香港教育大學語言學及現代語言系開發。特別鳴謝「語文教育及研究常務委員會」 資助本計劃。
This input method is developed by the Department of Linguistics and Modern Languages, the Education University of Hong Kong. Special thanks to the Standing Committee on Language Education and Research for funding this project.
""")

                                VStack {
                                        HStack(spacing: 20) {
                                                Image(.eduhk)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: 120)
                                                Image(.lml)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: 68)
                                                Image(.crlls)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: 84)
                                        }
                                        HStack(spacing: 50) {
                                                Image(.govfunded)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: 168)
                                                Image(.scolarlf)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: 140)
                                        }
                                }
                        }
                        .textSelection(.enabled)
                        .padding()
                }
                .navigationTitle("Preferences.HelpView.Title")
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
                        .frame(width: 270, alignment: .leading)
        }
}

private struct KeyBlockView: View {

        init(_ keyText: String) {
                self.keyText = keyText
        }

        private let keyText: String

        var body: some View {
                Text(verbatim: keyText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .frame(width: 72, height: 24)
                        .background(Material.regular, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        }

        static let control: KeyBlockView = KeyBlockView("Control ⌃")
        static let shift: KeyBlockView = KeyBlockView("Shift ⇧")
        static let number: KeyBlockView = KeyBlockView("number")
        static let space: KeyBlockView = KeyBlockView("Space ␣")
        static let escape: KeyBlockView = KeyBlockView("Esc ⎋")
        static let tab: KeyBlockView = KeyBlockView("Tab ⇥")

        /// Backspace. NOT Forward-Delete.
        static let backwardDelete: KeyBlockView = KeyBlockView("Delete ⌫")
}

private extension Text {
        static let separator: Text = Text(verbatim: ": ").foregroundColor(.secondary)
        static let plus: Text = Text(verbatim: "+")
        static let or: Text = Text("or")
}

private extension View {
        func block() -> some View {
                return self.padding().background(Color.textBackgroundColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
}

private extension Color {
        static let textBackgroundColor: Color = Color(nsColor: NSColor.textBackgroundColor)
}
