import SwiftUI
import CoreIME

struct OptionsView: View {

        @EnvironmentObject private var context: AppContext

        private let options: [String] = [
                "繁體",
                "简体",
                "半形",
                "全形",
                "中文標點",
                "英文標點",
                "表情符號",
                "無"
        ]

        private let characterStandard: CharacterStandard = Options.characterStandard
        private let characterForm: CharacterForm = Options.characterForm
        private let punctuationForm: PunctuationForm = Options.punctuationForm
        private let isEmojiSuggestionsOn: Bool = Options.isEmojiSuggestionsOn

        var body: some View {
                let highlightedIndex = context.optionsHighlightedIndex
                VStack(alignment: .leading, spacing: 0) {
                        Group {
                                SettingLabel(index: 0, highlightedIndex: highlightedIndex, text: options[0], checked: characterStandard.isTraditional)
                                SettingLabel(index: 1, highlightedIndex: highlightedIndex, text: options[1], checked: characterStandard.isSimplified)
                        }
                        Divider()
                        Group {
                                SettingLabel(index: 2, highlightedIndex: highlightedIndex, text: options[2], checked: characterForm == .halfWidth)
                                SettingLabel(index: 3, highlightedIndex: highlightedIndex, text: options[3], checked: characterForm == .fullWidth)
                        }
                        Divider()
                        Group {
                                SettingLabel(index: 4, highlightedIndex: highlightedIndex, text: options[4], checked: punctuationForm == .cantonese)
                                SettingLabel(index: 5, highlightedIndex: highlightedIndex, text: options[5], checked: punctuationForm == .english)
                        }
                        Divider()
                        Group {
                                SettingLabel(index: 6, highlightedIndex: highlightedIndex, text: options[6], checked: isEmojiSuggestionsOn)
                                SettingLabel(index: 7, highlightedIndex: highlightedIndex, text: options[7], checked: !isEmojiSuggestionsOn)
                        }
                }
                .padding(4)
                .roundedHUDVisualEffect()
                .padding(10)
                .fixedSize()
        }
}

private struct SettingLabel: View {

        let index: Int
        let highlightedIndex: Int
        let text: String
        let checked: Bool

        var body: some View {
                let isHighlighted: Bool = index == highlightedIndex
                HStack(spacing: 0) {
                        HStack(spacing: 14) {
                                SerialNumberLabel(index: index).foregroundStyle(isHighlighted ? Color.white : Color.secondary)
                                Text(verbatim: text).font(.candidate)
                        }
                        Spacer()
                        Image.checkmark.font(.title3).opacity(checked ? 1 : 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(isHighlighted ? Color.white : Color.primary)
                .background(isHighlighted ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
}
