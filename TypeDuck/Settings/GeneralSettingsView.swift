import SwiftUI

struct GeneralSettingsView: View {

        @AppStorage(SettingsKey.CandidatePageSize) private var pageSize: Int = AppSettings.candidatePageSize
        private let pageSizeRange: Range<Int> = AppSettings.candidatePageSizeRange

        @State private var isEnglishEnabled: Bool = Language.English.isEnabledCommentLanguage
        @State private var isHindiEnabled: Bool = Language.Hindi.isEnabledCommentLanguage
        @State private var isIndonesianEnabled: Bool = Language.Indonesian.isEnabledCommentLanguage
        @State private var isNepaliEnabled: Bool = Language.Nepali.isEnabledCommentLanguage
        @State private var isUrduEnabled: Bool = Language.Urdu.isEnabledCommentLanguage

        @AppStorage(SettingsKey.PrimaryCommentLanguage) var primaryCommentLanguageName: String = AppSettings.primaryCommentLanguage.name

        @State private var isEmojiSuggestionsOn: Bool = Options.isEmojiSuggestionsOn
        @State private var isInputMemoryOn: Bool = AppSettings.isInputMemoryOn

        @State private var isConfirmDialogPresented: Bool = false
        @State private var isPerformingClearUserLexicon: Bool = false
        @State private var clearUserLexiconProgress: Double = 0
        private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

        var body: some View {
                ScrollView {
                        LazyVStack(spacing: 16) {
                                HStack {
                                        Picker("SettingsView.GeneralSettingsView.Settings.CandidateCountPerPage", selection: $pageSize) {
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
                                VStack(spacing: 2) {
                                        HStack {
                                                Text("SettingsView.GeneralSettingsView.SectionHeader.DisplayLanguages").font(.subheadline).padding(.horizontal)
                                                Spacer()
                                        }
                                        VStack(alignment: .leading, spacing: 24) {
                                                VStack(alignment: .leading) {
                                                        HStack {
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.English")
                                                                Spacer()
                                                                Toggle("SettingsView.GeneralSettingsView.CommentLanguage.English", isOn: $isEnglishEnabled)
                                                                        .toggleStyle(.switch)
                                                                        .labelsHidden()
                                                                        .scaledToFit()
                                                                        .onChange(of: isEnglishEnabled) { newState in
                                                                                let language: Language = .English
                                                                                let isEnabled: Bool = language.isEnabledCommentLanguage
                                                                                let shouldEnable: Bool = !isEnabled
                                                                                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
                                                                        }
                                                        }
                                                        HStack {
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Hindi")
                                                                Spacer()
                                                                Toggle("SettingsView.GeneralSettingsView.CommentLanguage.Hindi", isOn: $isHindiEnabled)
                                                                        .toggleStyle(.switch)
                                                                        .labelsHidden()
                                                                        .scaledToFit()
                                                                        .onChange(of: isHindiEnabled) { newState in
                                                                                let language: Language = .Hindi
                                                                                let isEnabled: Bool = language.isEnabledCommentLanguage
                                                                                let shouldEnable: Bool = !isEnabled
                                                                                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
                                                                        }
                                                        }
                                                        HStack {
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Indonesian")
                                                                Spacer()
                                                                Toggle("SettingsView.GeneralSettingsView.CommentLanguage.Indonesian", isOn: $isIndonesianEnabled)
                                                                        .toggleStyle(.switch)
                                                                        .labelsHidden()
                                                                        .scaledToFit()
                                                                        .onChange(of: isIndonesianEnabled) { newState in
                                                                                let language: Language = .Indonesian
                                                                                let isEnabled: Bool = language.isEnabledCommentLanguage
                                                                                let shouldEnable: Bool = !isEnabled
                                                                                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
                                                                        }
                                                        }
                                                        HStack {
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Nepali")
                                                                Spacer()
                                                                Toggle("SettingsView.GeneralSettingsView.CommentLanguage.Nepali", isOn: $isNepaliEnabled)
                                                                        .toggleStyle(.switch)
                                                                        .labelsHidden()
                                                                        .scaledToFit()
                                                                        .onChange(of: isNepaliEnabled) { newState in
                                                                                let language: Language = .Nepali
                                                                                let isEnabled: Bool = language.isEnabledCommentLanguage
                                                                                let shouldEnable: Bool = !isEnabled
                                                                                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
                                                                        }
                                                        }
                                                        HStack {
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Urdu")
                                                                Spacer()
                                                                Toggle("SettingsView.GeneralSettingsView.CommentLanguage.Urdu", isOn: $isUrduEnabled)
                                                                        .toggleStyle(.switch)
                                                                        .labelsHidden()
                                                                        .scaledToFit()
                                                                        .onChange(of: isUrduEnabled) { newState in
                                                                                let language: Language = .Urdu
                                                                                let isEnabled: Bool = language.isEnabledCommentLanguage
                                                                                let shouldEnable: Bool = !isEnabled
                                                                                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
                                                                        }
                                                        }
                                                }
                                                .fixedSize()
                                                HStack {
                                                        Picker("SettingsView.GeneralSettingsView.Settings.PrimaryCommentLanguage", selection: $primaryCommentLanguageName) {
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.English").tag(Language.English.name)
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Hindi").tag(Language.Hindi.name)
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Indonesian").tag(Language.Indonesian.name)
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Nepali").tag(Language.Nepali.name)
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Urdu").tag(Language.Urdu.name)
                                                        }
                                                        .scaledToFit()
                                                        .onChange(of: primaryCommentLanguageName) { newLanguageName in
                                                                AppSettings.updatePrimaryCommentLanguage(to: newLanguageName)
                                                        }
                                                        Spacer()
                                                }
                                        }
                                        .block()
                                }
                                HStack {
                                        Toggle("SettingsView.GeneralSettingsView.Settings.EmojiSuggestions", isOn: $isEmojiSuggestionsOn)
                                                .toggleStyle(.switch)
                                                .scaledToFit()
                                                .onChange(of: isEmojiSuggestionsOn) { newState in
                                                        Options.updateEmojiSuggestions(to: newState)
                                                }
                                        Spacer()
                                }
                                .block()
                                VStack(spacing: 2) {
                                        HStack {
                                                Text("GeneralSettingsView.SectionHeader.UserLexicon").font(.subheadline).padding(.horizontal)
                                                Spacer()
                                        }
                                        VStack(spacing: 26) {
                                                HStack {
                                                        Toggle("GeneralSettingsView.Toggle.InputMemory", isOn: $isInputMemoryOn)
                                                                .toggleStyle(.switch)
                                                                .scaledToFit()
                                                                .onChange(of: isInputMemoryOn) { newState in
                                                                        AppSettings.updateInputMemory(to: newState)
                                                                }
                                                        Spacer()
                                                }
                                                HStack {
                                                        VStack(alignment: .leading, spacing: 1) {
                                                                Button(role: .destructive) {
                                                                        isConfirmDialogPresented = true
                                                                } label: {
                                                                        Text("GeneralSettingsView.Button.ClearUserLexicon")
                                                                }
                                                                .buttonStyle(.plain)
                                                                .padding(.horizontal, 8)
                                                                .padding(.vertical, 4)
                                                                .foregroundStyle(Color.red)
                                                                .background(Material.thick, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                                                .confirmationDialog("GeneralSettingsView.ConfirmationDialog.ClearUserLexicon.Title", isPresented: $isConfirmDialogPresented) {
                                                                        Button("GeneralSettingsView.ConfirmationDialog.ClearUserLexicon.Confirm", role: .destructive) {
                                                                                clearUserLexiconProgress = 0
                                                                                isPerformingClearUserLexicon = true
                                                                                UserLexicon.deleteAll()
                                                                        }
                                                                        Button("GeneralSettingsView.ConfirmationDialog.ClearUserLexicon.Cancel", role: .cancel) {
                                                                                isConfirmDialogPresented = false
                                                                        }
                                                                }
                                                                ProgressView(value: clearUserLexiconProgress).opacity(isPerformingClearUserLexicon ? 1 : 0)
                                                        }
                                                        .fixedSize()
                                                        .onReceive(timer) { _ in
                                                                guard isPerformingClearUserLexicon else { return }
                                                                if clearUserLexiconProgress > 1 {
                                                                        isPerformingClearUserLexicon = false
                                                                } else {
                                                                        clearUserLexiconProgress += 0.1
                                                                }
                                                        }
                                                        Spacer()
                                                }
                                        }
                                        .block()
                                }
                        }
                        .textSelection(.enabled)
                        .padding()
                }
                .navigationTitle("SettingsView.GeneralSettingsView.Title")
        }
}

#Preview {
        GeneralSettingsView()
}
