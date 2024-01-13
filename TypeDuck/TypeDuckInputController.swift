import SwiftUI
import InputMethodKit
import CoreIME

@objc(TypeDuckInputController)
final class TypeDuckInputController: IMKInputController {

        // MARK: - Window, InputClient

        private lazy var window: NSPanel? = nil
        private func createMasterWindow() {
                _ = window?.contentView?.subviews.map({ $0.removeFromSuperview() })
                _ = window?.contentViewController?.children.map({ $0.removeFromParent() })
                window = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
                let levelValue: Int = Int(CGShieldingWindowLevel())
                window?.level = NSWindow.Level(levelValue)
                window?.isFloatingPanel = true
                window?.worksWhenModal = true
                window?.hidesOnDeactivate = false
                window?.isReleasedWhenClosed = true
                window?.collectionBehavior = .moveToActiveSpace
                window?.isMovable = true
                window?.isMovableByWindowBackground = true
                window?.isOpaque = false
                window?.hasShadow = false
                window?.backgroundColor = .clear
                let motherBoard = NSHostingController(rootView: MotherBoard().environmentObject(appContext))
                window?.contentView?.addSubview(motherBoard.view)
                motherBoard.view.translatesAutoresizingMaskIntoConstraints = false
                let offset: CGFloat = 10
                if let topAnchor = window?.contentView?.topAnchor,
                   let bottomAnchor = window?.contentView?.bottomAnchor,
                   let leadingAnchor = window?.contentView?.leadingAnchor,
                   let trailingAnchor = window?.contentView?.trailingAnchor {
                        NSLayoutConstraint.activate([
                                motherBoard.view.topAnchor.constraint(equalTo: topAnchor, constant: offset),
                                motherBoard.view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -offset),
                                motherBoard.view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: offset),
                                motherBoard.view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -offset)
                        ])
                }
                window?.contentViewController?.addChild(motherBoard)
                window?.orderFrontRegardless()
        }
        private func prepareMasterWindow() {
                if let isOnActiveSpace: Bool = window?.isOnActiveSpace {
                        if !(isOnActiveSpace) {
                                window?.orderFrontRegardless()
                        }
                } else {
                        createMasterWindow()
                }
                let idealValue: Int = Int(CGShieldingWindowLevel())
                let maxValue: Int = idealValue + 2
                let levelValue: Int = {
                        guard let clientLevel = currentClient?.windowLevel() else { return idealValue }
                        let increasedValue: Int = Int(clientLevel) + 1
                        return min(increasedValue, maxValue)
                }()
                window?.level = NSWindow.Level(levelValue)
        }
        func updateMasterWindow() {
                if window == nil {
                        createMasterWindow()
                }
                window?.setFrame(windowFrame, display: true)
        }
        func setWindowFrame(_ frame: CGRect) {
                window?.setFrame(frame, display: true)
        }

        var windowFrame: CGRect {
                let origin: CGPoint = currentOrigin ?? currentClient?.position ?? .zero
                let width: CGFloat = 800
                let height: CGFloat = 500
                let x: CGFloat = {
                        if appContext.windowPattern.isReversingHorizontal {
                                return origin.x - width - 8
                        } else {
                                return origin.x
                        }
                }()
                let y: CGFloat = {
                        if appContext.windowPattern.isReversingVertical {
                                return origin.y + 16
                        } else {
                                return origin.y - height
                        }
                }()
                return CGRect(x: x, y: y, width: width, height: height)
        }

        private lazy var screenWidth: CGFloat = NSScreen.main?.frame.size.width ?? 1920
        lazy var currentOrigin: CGPoint? = nil
        lazy var currentClient: IMKTextInput? = nil {
                didSet {
                        guard let origin = currentClient?.position else { return }
                        let isRegularHorizontal: Bool = origin.x < (screenWidth - 400)
                        let isRegularVertical: Bool = origin.y > 400
                        let newPattern: WindowPattern = {
                                switch (isRegularHorizontal, isRegularVertical) {
                                case (true, true):
                                        return .regular
                                case (false, true):
                                        return .horizontalReversed
                                case (true, false):
                                        return .verticalReversed
                                case (false, false):
                                        return .reversed
                                }
                        }()
                        guard newPattern != appContext.windowPattern else { return }
                        appContext.updateWindowPattern(to: newPattern)
                }
        }


        // MARK: - Input Server lifecycle

        override func activateServer(_ sender: Any!) {
                UserLexicon.prepare()
                Engine.prepare()
                screenWidth = NSScreen.main?.frame.size.width ?? 1920
                if inputStage.isBuffering {
                        clearBufferText()
                }
                currentClient = sender as? IMKTextInput
                currentOrigin = currentClient?.position
                DispatchQueue.main.async { [weak self] in
                        self?.currentClient?.overrideKeyboard(withKeyboardNamed: "com.apple.keylayout.ABC")
                }
                prepareMasterWindow()
                if appContext.inputForm.isOptions {
                        appContext.updateInputForm()
                }
        }
        override func deactivateServer(_ sender: Any!) {
                selectedCandidates = []
                if appContext.inputForm.isOptions {
                        clearOptionsViewHintText()
                        appContext.updateInputForm()
                }
                if inputStage.isBuffering {
                        let text: String = bufferText
                        clearBufferText()
                        (sender as? IMKTextInput)?.insert(text)
                }
                if NSApp.windows.count > 5 {
                        _ = NSApp.windows.map({ $0.close() })
                } else {
                        window?.setFrame(.zero, display: true)
                }
        }

        private(set) lazy var appContext: AppContext = AppContext()


        // MARK: - Input Texts

        private(set) lazy var inputStage: InputStage = .standby
        lazy var bufferText: String = .empty {
                willSet {
                        switch (bufferText.isEmpty, newValue.isEmpty) {
                        case (true, true):
                                inputStage = .standby
                        case (true, false):
                                inputStage = .starting
                                UserLexicon.prepare()
                                Engine.prepare()
                        case (false, true):
                                inputStage = .ending
                                let shouldHandleSelectedCandidates: Bool = !(selectedCandidates.isEmpty)
                                guard shouldHandleSelectedCandidates else { return }
                                let concatenated: Candidate = selectedCandidates.joined()
                                selectedCandidates = []
                                UserLexicon.handle(concatenated)
                        case (false, false):
                                inputStage = .ongoing
                        }
                }
                didSet {
                        switch bufferText.first {
                        case .none:
                                clearMarkedText()
                                candidates = []
                        case .some(let character) where character.isBasicLatinLetter:
                                suggest()
                        case .some(_) where bufferText.count == 1:
                                mark(text: bufferText)
                                handlePunctuation()
                        case .some(.backtick):
                                switch bufferText.dropFirst().first {
                                case .some("p"), .some("r"):
                                        pinyinReverseLookup()
                                case .some("c"), .some("v"):
                                        cangjieReverseLookup()
                                case .some("s"), .some("x"), .some("b"):
                                        strokeReverseLookup()
                                case .some("l"), .some("q"):
                                        composeReverseLookup()
                                default:
                                        mark(text: bufferText)
                                }
                        default:
                                mark(text: bufferText)
                        }
                }
        }
        func clearBufferText() {
                bufferText = .empty
        }

        private func mark(text: String) {
                let markAttributes = mark(forStyle: kTSMHiliteSelectedConvertedText, at: NSRange(location: NSNotFound, length: 0))
                let fallbackAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.thick.rawValue]
                let attributes = (markAttributes as? [NSAttributedString.Key: Any]) ?? fallbackAttributes
                let attributedText = NSAttributedString(string: text, attributes: attributes)
                let selectionRange = NSRange(location: text.utf16.count, length: 0)
                currentClient?.setMarkedText(attributedText, selectionRange: selectionRange, replacementRange: NSRange(location: NSNotFound, length: 0))
        }
        private func clearMarkedText() {
                let markAttributes = mark(forStyle: kTSMHiliteSelectedConvertedText, at: NSRange(location: NSNotFound, length: 0))
                let fallbackAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.thick.rawValue]
                let attributes = (markAttributes as? [NSAttributedString.Key: Any]) ?? fallbackAttributes
                let attributedText = NSAttributedString(string: String(), attributes: attributes)
                let selectionRange = NSRange(location: 0, length: 0)
                currentClient?.setMarkedText(attributedText, selectionRange: selectionRange, replacementRange: NSRange(location: NSNotFound, length: 0))
        }
        func markOptionsViewHintText() {
                guard !(inputStage.isBuffering) else { return }
                mark(text: String.zeroWidthSpace)
        }
        func clearOptionsViewHintText() {
                guard !(inputStage.isBuffering) else { return }
                clearMarkedText()
        }


        // MARK: - Candidates

        /// Cached Candidate sequence for UserLexicon
        lazy var selectedCandidates: [Candidate] = []

        private(set) lazy var candidates: [Candidate] = [] {
                willSet {
                        switch (candidates.isEmpty, newValue.isEmpty) {
                        case (true, true):
                                // Stay empty
                                window?.setFrame(.zero, display: true)
                        case (true, false):
                                // Become un-empty
                                updateMasterWindow()
                        case (false, true):
                                // End up to be empty
                                window?.setFrame(.zero, display: true)
                        case (false, false):
                                // Ongoing
                                updateMasterWindow()
                        }
                }
                didSet {
                        updateDisplayCandidates(.establish, highlight: .start)
                        guard !(candidates.isEmpty) else { return }
                        let windowWidth: CGFloat = window?.frame.size.width ?? 0
                        let shouldResetWindow: Bool = windowWidth < 100
                        guard shouldResetWindow else { return }
                        window?.close()
                        createMasterWindow()
                        setWindowFrame(windowFrame)
                }
        }

        /// DisplayCandidates indices
        private lazy var indices: (first: Int, last: Int) = (0, 0)

        func updateDisplayCandidates(_ transformation: PageTransformation, highlight: Highlight) {
                let candidateCount: Int = candidates.count
                guard candidateCount > 0 else {
                        indices = (0, 0)
                        appContext.resetDisplayContext()
                        return
                }
                let pageSize: Int = AppSettings.pageSize
                let newFirstIndex: Int? = {
                        switch transformation {
                        case .establish:
                                return 0
                        case .previousPage:
                                let oldFirstIndex: Int = indices.first
                                guard oldFirstIndex > 0 else { return nil }
                                return max(0, oldFirstIndex - pageSize)
                        case .nextPage:
                                let oldLastIndex: Int = indices.last
                                let maxIndex: Int = candidateCount - 1
                                guard oldLastIndex < maxIndex else { return nil }
                                return oldLastIndex + 1
                        }
                }()
                guard let firstIndex: Int = newFirstIndex else { return }
                let bound: Int = min(firstIndex + pageSize, candidateCount)
                indices = (firstIndex, bound - 1)
                let newDisplayCandidates = (firstIndex..<bound).map({ index -> DisplayCandidate in
                        return DisplayCandidate(candidate: candidates[index], candidateIndex: index)
                })
                appContext.update(with: newDisplayCandidates, highlight: highlight)
        }


        // MARK: - Candidate Suggestions

        private func suggest() {
                let processingText = bufferText.toneConverted()
                let segmentation = Segmentor.segment(text: processingText)
                let text2mark: String = {
                        let isMarkFree: Bool = processingText.first(where: { $0.isSeparatorOrTone }) == nil
                        guard isMarkFree else { return processingText.formattedForMark() }
                        guard let bestScheme = segmentation.first else { return processingText.formattedForMark() }
                        let leadingLength: Int = bestScheme.length
                        let leadingText: String = bestScheme.map(\.text).joined(separator: " ")
                        guard leadingLength != processingText.count else { return leadingText }
                        let tailText = processingText.dropFirst(leadingLength)
                        return leadingText + " " + tailText
                }()
                mark(text: text2mark)
                let engineCandidates: [Candidate] = {
                        var suggestion: [Candidate] = Engine.suggest(text: processingText, segmentation: segmentation)
                        let shouldContinue: Bool = Options.isEmojiSuggestionsOn && !suggestion.isEmpty && selectedCandidates.isEmpty
                        guard shouldContinue else { return suggestion }
                        let symbols: [Candidate] = Engine.searchSymbols(text: bufferText, segmentation: segmentation)
                        guard !(symbols.isEmpty) else { return suggestion }
                        for symbol in symbols.reversed() {
                                if let index = suggestion.firstIndex(where: { $0.lexiconText == symbol.lexiconText }) {
                                        suggestion.insert(symbol, at: index + 1)
                                }
                        }
                        return suggestion
                }()
                let userSuggestions: [Candidate] = UserLexicon.suggest(text: processingText, segmentation: segmentation)
                let userCandidates: [Candidate] = userSuggestions.map({ origin -> Candidate in
                        let notation: Notation? = Engine.fetchNotation(word: origin.lexiconText, romanization: origin.romanization)
                        return Candidate(text: origin.text, romanization: origin.romanization, input: origin.input, lexiconText: origin.lexiconText, notation: notation)
                })
                let combined: [Candidate] = userCandidates + engineCandidates
                candidates = combined.map({ $0.transformed(to: Options.characterStandard) }).uniqued()
        }
        private func pinyinReverseLookup() {
                let text: String = String(bufferText.dropFirst(2))
                guard !(text.isEmpty) else {
                        mark(text: bufferText)
                        candidates = []
                        return
                }
                let schemes: [[String]] = PinyinSegmentor.segment(text: text)
                let tailMarkedText: String = {
                        guard let bestScheme = schemes.first else { return text }
                        let leadingLength: Int = bestScheme.summedLength
                        let leadingText: String = bestScheme.joined(separator: " ")
                        guard leadingLength != text.count else { return leadingText }
                        let tailText = text.dropFirst(leadingLength)
                        return leadingText + " " + tailText
                }()
                let head = bufferText.prefix(2) + " "
                let text2mark: String = head + tailMarkedText
                mark(text: text2mark)
                let lookup: [Candidate] = Engine.pinyinReverseLookup(text: text, schemes: schemes)
                candidates = lookup.map({ $0.transformed(to: Options.characterStandard) }).uniqued()
        }
        private func cangjieReverseLookup() {
                let text: String = String(bufferText.dropFirst(2))
                let converted = text.map({ CharacterStandard.cangjie(of: $0) }).compactMap({ $0 })
                let isValidSequence: Bool = !(converted.isEmpty) && (converted.count == text.count)
                if isValidSequence {
                        mark(text: String(converted))
                        let lookup: [Candidate] = Engine.cangjieReverseLookup(text: text)
                        candidates = lookup.map({ $0.transformed(to: Options.characterStandard) }).uniqued()
                } else {
                        mark(text: bufferText)
                        candidates = []
                }
        }
        private func strokeReverseLookup() {
                let text: String = String(bufferText.dropFirst(2))
                let transformed: String = CharacterStandard.strokeTransform(text)
                let converted = transformed.map({ CharacterStandard.stroke(of: $0) }).compactMap({ $0 })
                let isValidSequence: Bool = !(converted.isEmpty) && (converted.count == text.count)
                if isValidSequence {
                        mark(text: String(converted))
                        let lookup: [Candidate] = Engine.strokeReverseLookup(text: transformed)
                        candidates = lookup.map({ $0.transformed(to: Options.characterStandard) }).uniqued()
                } else {
                        mark(text: bufferText)
                        candidates = []
                }
        }
        /// Compose(LoengFan) Reverse Lookup
        private func composeReverseLookup() {
                guard bufferText.count > 3 else {
                        mark(text: bufferText)
                        candidates = []
                        return
                }
                let text = bufferText.dropFirst(2).toneConverted()
                let segmentation = Segmentor.segment(text: text)
                let tailMarkedText: String = {
                        let isMarkFree: Bool = text.first(where: { $0.isSeparatorOrTone }) == nil
                        guard isMarkFree else { return text.formattedForMark() }
                        guard let bestScheme = segmentation.first else { return text.formattedForMark() }
                        let leadingLength: Int = bestScheme.length
                        let leadingText: String = bestScheme.map(\.text).joined(separator: " ")
                        guard leadingLength != text.count else { return leadingText }
                        let tailText = text.dropFirst(leadingLength)
                        return leadingText + " " + tailText
                }()
                let head = bufferText.prefix(2) + " "
                let text2mark: String = head + tailMarkedText
                mark(text: text2mark)
                let lookup: [Candidate] = Engine.composeReverseLookup(text: text, input: bufferText, segmentation: segmentation)
                candidates = lookup.map({ $0.transformed(to: Options.characterStandard) }).uniqued()
        }

        private func handlePunctuation() {
                let symbols: [PunctuationSymbol] = {
                        switch bufferText {
                        case PunctuationKey.comma.shiftingKeyText:
                                return PunctuationKey.comma.shiftingSymbols
                        case PunctuationKey.period.shiftingKeyText:
                                return PunctuationKey.period.shiftingSymbols
                        case PunctuationKey.slash.keyText:
                                return PunctuationKey.slash.symbols
                        case PunctuationKey.bracketLeft.shiftingKeyText:
                                return PunctuationKey.bracketLeft.shiftingSymbols
                        case PunctuationKey.bracketRight.shiftingKeyText:
                                return PunctuationKey.bracketRight.shiftingSymbols
                        case PunctuationKey.backSlash.shiftingKeyText:
                                return PunctuationKey.backSlash.shiftingSymbols
                        case PunctuationKey.backquote.keyText:
                                return PunctuationKey.backquote.symbols
                        case PunctuationKey.backquote.shiftingKeyText:
                                return PunctuationKey.backquote.shiftingSymbols
                        default:
                                return []
                        }
                }()
                candidates = symbols.map({ Candidate(text: $0.symbol, comment: $0.comment, secondaryComment: $0.secondaryComment, input: bufferText) })
        }
}
