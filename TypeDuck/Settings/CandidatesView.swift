import SwiftUI

struct CandidatesView: View {

        @AppStorage(SettingsKey.CandidatePageSize) private var pageSize: Int = AppSettings.candidatePageSize
        private let pageSizeRange: Range<Int> = AppSettings.candidatePageSizeRange

        @State private var isEmojiSuggestionsOn: Bool = Options.isEmojiSuggestionsOn

        var body: some View {
                ScrollView {
                        LazyVStack(spacing: 16) {
                                HStack {
                                        Toggle("Emoji Suggestions", isOn: $isEmojiSuggestionsOn)
                                                .toggleStyle(.switch)
                                                .scaledToFit()
                                                .onChange(of: isEmojiSuggestionsOn) { newState in
                                                        Options.updateEmojiSuggestions(to: newState)
                                                }
                                        Spacer()
                                }
                                .block()
                                HStack {
                                        Picker("Candidate Count Per Page", selection: $pageSize) {
                                                ForEach(pageSizeRange, id: \.self) {
                                                        Text(verbatim: "\($0)").tag($0)
                                                }
                                        }
                                        .scaledToFit()
                                        .onChange(of: pageSize) { newPageSize in
                                                AppSettings.updateCandidatePageSize(to: newPageSize)
                                        }
                                        Spacer()
                                }
                                .block()
                        }
                        .textSelection(.enabled)
                        .padding()
                }
                .navigationTitle("SettingsView.CandidatesView.Title")
        }
}

#Preview {
        CandidatesView()
}
