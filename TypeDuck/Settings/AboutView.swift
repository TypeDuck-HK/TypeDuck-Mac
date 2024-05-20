import SwiftUI

struct AboutView: View {

        // We'd like to parse Markdown but don't need to localize the text.
        private let typeDuckDescription: AttributedString = {

let source: String = """
歡迎使用 TypeDuck 打得 —— 設有少數族裔語言提示粵拼輸入法！有字想打？一裝即用，毋須再等，即刻打得！
Welcome to TypeDuck: a Cantonese input keyboard with minority language prompts! Got something you want to type? Have your fingers ready, get, set, TYPE DUCK!

如有任何查詢，歡迎電郵至 [info@typeduck.hk](mailto:info@typeduck.hk?subject=Mac%20TypeDuck%20Enquiry%20/%20Issue%20Report%20%7C%20%E6%89%93%E5%BE%97%E7%B2%B5%E8%AA%9E%E8%BC%B8%E5%85%A5%E6%B3%95%E6%9F%A5%E8%A9%A2%EF%BC%8F%E5%95%8F%E9%A1%8C%E5%8C%AF%E5%A0%B1) 或 [lchaakming@eduhk.hk](mailto:lchaakming@eduhk.hk?subject=Mac%20TypeDuck%20Enquiry%20/%20Issue%20Report%20%7C%20%E6%89%93%E5%BE%97%E7%B2%B5%E8%AA%9E%E8%BC%B8%E5%85%A5%E6%B3%95%E6%9F%A5%E8%A9%A2%EF%BC%8F%E5%95%8F%E9%A1%8C%E5%8C%AF%E5%A0%B1)
Should you have any enquiries, please email [info@typeduck.hk](mailto:info@typeduck.hk?subject=Mac%20TypeDuck%20Enquiry%20/%20Issue%20Report%20%7C%20%E6%89%93%E5%BE%97%E7%B2%B5%E8%AA%9E%E8%BC%B8%E5%85%A5%E6%B3%95%E6%9F%A5%E8%A9%A2%EF%BC%8F%E5%95%8F%E9%A1%8C%E5%8C%AF%E5%A0%B1) or [lchaakming@eduhk.hk](mailto:lchaakming@eduhk.hk?subject=Mac%20TypeDuck%20Enquiry%20/%20Issue%20Report%20%7C%20%E6%89%93%E5%BE%97%E7%B2%B5%E8%AA%9E%E8%BC%B8%E5%85%A5%E6%B3%95%E6%9F%A5%E8%A9%A2%EF%BC%8F%E5%95%8F%E9%A1%8C%E5%8C%AF%E5%A0%B1)

本輸入法由香港教育大學語言學及現代語言系開發。特別鳴謝「語文教育及研究常務委員會」資助本計劃。
This input method is developed by the Department of Linguistics and Modern Language Studies, the Education University of Hong Kong. Special thanks to the Standing Committee on Language Education and Research for funding this project.
"""

                return (try? AttributedString(markdown: source, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(source)
        }()

        var body: some View {
                ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                                Text("SettingsView.AboutView.Welcome").font(.title3.bold())
                                Text(typeDuckDescription)
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

                                HStack(spacing: 0) {
                                        Spacer()
                                        Text("SettingsView.AboutView.Version").fontWeight(.semibold)
                                        Text("SettingsView.Colon").foregroundColor(.secondary)
                                        Text(verbatim: AppSettings.version)
                                        Spacer()
                                }
                                .padding(.top)
                        }
                        .textSelection(.enabled)
                        .padding()
                }
                .navigationTitle("SettingsView.AboutView.Title")
        }
}

#Preview {
        AboutView()
}
