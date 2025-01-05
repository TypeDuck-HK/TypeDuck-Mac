import SwiftUI
import CoreIME

struct GeneralSettingsView: View {

        @State private var pageSize: Int = AppSettings.candidatePageSize
        private let pageSizeRange: Range<Int> = AppSettings.candidatePageSizeRange

        @State private var isEnglishEnabled: Bool = Language.English.isEnabledCommentLanguage
        @State private var isHindiEnabled: Bool = Language.Hindi.isEnabledCommentLanguage
        @State private var isIndonesianEnabled: Bool = Language.Indonesian.isEnabledCommentLanguage
        @State private var isNepaliEnabled: Bool = Language.Nepali.isEnabledCommentLanguage
        @State private var isUrduEnabled: Bool = Language.Urdu.isEnabledCommentLanguage
        @State private var primaryCommentLanguage: Language = AppSettings.primaryCommentLanguage

        @State private var isEmojiSuggestionsOn: Bool = Options.isEmojiSuggestionsOn
        @State private var cangjieVariant: CangjieVariant = AppSettings.cangjieVariant
        @State private var isInputMemoryOn: Bool = AppSettings.isInputMemoryOn

        @State private var isClearInputMemoryConfirmDialogPresented: Bool = false
        @State private var isPerformingClearInputMemory: Bool = false
        @State private var clearInputMemoryProgress: Double = 0
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
                                        .pickerStyle(.menu)
                                        .scaledToFit()
                                        .onChange(of: pageSize) { newPageSize in
                                                AppSettings.updateCandidatePageSize(to: newPageSize)
                                        }
                                        Spacer()
                                }
                                .block()
                                VStack(spacing: 2) {
                                        HStack {
                                                Text("SettingsView.GeneralSettingsView.SectionHeader.DisplayLanguages")
                                                Spacer()
                                        }
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
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
                                                        Picker("SettingsView.GeneralSettingsView.Settings.PrimaryCommentLanguage", selection: $primaryCommentLanguage) {
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.English").tag(Language.English)
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Hindi").tag(Language.Hindi)
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Indonesian").tag(Language.Indonesian)
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Nepali").tag(Language.Nepali)
                                                                Text("SettingsView.GeneralSettingsView.CommentLanguage.Urdu").tag(Language.Urdu)
                                                        }
                                                        .pickerStyle(.menu)
                                                        .scaledToFit()
                                                        .onChange(of: primaryCommentLanguage) { newLanguage in
                                                                AppSettings.updatePrimaryCommentLanguage(to: newLanguage)
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
                                                Text("GeneralSettingsView.SectionHeader.ReverseLookup")
                                                Spacer()
                                        }
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        HStack {
                                                Picker("GeneralSettingsView.CangjieVariant.Picker.TitleKey", selection: $cangjieVariant) {
                                                        Text("GeneralSettingsView.CangjieVariant.Picker.Option1").tag(CangjieVariant.cangjie5)
                                                        Text("GeneralSettingsView.CangjieVariant.Picker.Option2").tag(CangjieVariant.cangjie3)
                                                        Text("GeneralSettingsView.CangjieVariant.Picker.Option3").tag(CangjieVariant.quick5)
                                                        Text("GeneralSettingsView.CangjieVariant.Picker.Option4").tag(CangjieVariant.quick3)
                                                }
                                                .pickerStyle(.menu)
                                                .scaledToFit()
                                                .onChange(of: cangjieVariant) { newVariant in
                                                        AppSettings.updateCangjieVariant(to: newVariant)
                                                }
                                                Spacer()
                                        }
                                        .block()
                                }
                                VStack(spacing: 20) {
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
                                                                isClearInputMemoryConfirmDialogPresented = true
                                                        } label: {
                                                                Text("GeneralSettingsView.Button.ClearInputMemory")
                                                        }
                                                        .buttonStyle(.plain)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .foregroundStyle(Color.red)
                                                        .background(Material.thick, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                                        .confirmationDialog("GeneralSettingsView.ConfirmationDialog.ClearInputMemory.Title", isPresented: $isClearInputMemoryConfirmDialogPresented) {
                                                                Button("GeneralSettingsView.ConfirmationDialog.ClearInputMemory.Confirm", role: .destructive) {
                                                                        clearInputMemoryProgress = 0
                                                                        isPerformingClearInputMemory = true
                                                                        UserLexicon.deleteAll()
                                                                }
                                                                Button("GeneralSettingsView.ConfirmationDialog.ClearInputMemory.Cancel", role: .cancel) {
                                                                        isClearInputMemoryConfirmDialogPresented = false
                                                                }
                                                        }
                                                        ProgressView(value: clearInputMemoryProgress).opacity(isPerformingClearInputMemory ? 1 : 0)
                                                }
                                                .fixedSize()
                                                .onReceive(timer) { _ in
                                                        guard isPerformingClearInputMemory else { return }
                                                        if clearInputMemoryProgress > 1 {
                                                                isPerformingClearInputMemory = false
                                                        } else {
                                                                clearInputMemoryProgress += 0.1
                                                        }
                                                }
                                                Spacer()
                                        }
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, 12)
                                .padding(.bottom, 1)
                                .background(Color.textBackgroundColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
