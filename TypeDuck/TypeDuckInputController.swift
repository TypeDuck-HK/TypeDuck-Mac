import SwiftUI
import InputMethodKit
import CoreIME

@objc(TypeDuckInputController)
final class TypeDuckInputController: IMKInputController {

        // MARK: - Window, InputClient

        @MainActor
        private let window: NSPanel = {
                let panel: NSPanel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
                let levelValue: Int = Int(CGShieldingWindowLevel())
                panel.level = NSWindow.Level(levelValue)
                panel.isFloatingPanel = true
                panel.worksWhenModal = true
                panel.hidesOnDeactivate = false
                panel.isReleasedWhenClosed = true
                panel.collectionBehavior = .moveToActiveSpace
                panel.isMovable = true
                panel.isMovableByWindowBackground = true
                panel.isOpaque = false
                panel.hasShadow = false
                panel.backgroundColor = .clear
                return panel
        }()
        private func prepareMasterWindow() {
                _ = window.contentView?.subviews.map({ $0.removeFromSuperview() })
                _ = window.contentViewController?.children.map({ $0.removeFromParent() })
                let idealValue: Int = Int(CGShieldingWindowLevel())
                let maxValue: Int = idealValue + 2
                let minValue: Int = NSWindow.Level.floating.rawValue
                let levelValue: Int = {
                        guard let clientLevel = currentClient?.windowLevel() else { return idealValue }
                        let preferredValue: Int = Int(clientLevel) + 1
                        guard preferredValue > minValue else { return idealValue }
                        guard preferredValue < maxValue else { return maxValue }
                        return preferredValue
                }()
                window.level = NSWindow.Level(levelValue)
                let motherBoard = NSHostingController(rootView: MotherBoard().environmentObject(appContext))
                window.contentView?.addSubview(motherBoard.view)
                motherBoard.view.translatesAutoresizingMaskIntoConstraints = false
                let offset: CGFloat = 10
                if let topAnchor = window.contentView?.topAnchor,
                   let bottomAnchor = window.contentView?.bottomAnchor,
                   let leadingAnchor = window.contentView?.leadingAnchor,
                   let trailingAnchor = window.contentView?.trailingAnchor {
                        NSLayoutConstraint.activate([
                                motherBoard.view.topAnchor.constraint(equalTo: topAnchor, constant: offset),
                                motherBoard.view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -offset),
                                motherBoard.view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: offset),
                                motherBoard.view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -offset)
                        ])
                }
                window.contentViewController?.addChild(motherBoard)
                window.orderFrontRegardless()
        }
        private func clearMasterWindow() {
                _ = window.contentView?.subviews.map({ $0.removeFromSuperview() })
                _ = window.contentViewController?.children.map({ $0.removeFromParent() })
                window.setFrame(.zero, display: true)
        }
        func updateWindowFrame(_ frame: CGRect? = nil, shouldUpdateOrigin: Bool = true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                        let frame: CGRect = frame ?? self?.windowFrame ?? .zero
                        if shouldUpdateOrigin {
                                self?.window.setFrame(frame, display: true)
                        } else {
                                self?.window.setContentSize(frame.size)
                        }
                }
        }
        private var windowFrame: CGRect {
                let origin: CGPoint = currentOrigin ?? currentClient?.position ?? .zero
                let offset: CGFloat = 10
                let viewSize: CGSize = window.contentView?.subviews.first?.bounds.size ?? CGSize(width: 800, height: 500)
                let width: CGFloat = viewSize.width + (offset * 2)
                let height: CGFloat = viewSize.height + (offset * 2)
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

        private lazy var screenWidth: CGFloat = NSScreen.main?.visibleFrame.size.width ?? 1920
        lazy var currentOrigin: CGPoint? = nil

        typealias InputClient = (IMKTextInput & NSObjectProtocol)
        lazy var currentClient: InputClient? = nil {
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

        override init() {
                super.init()
                activateServer(client())
        }
        override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
                super.init(server: server, delegate: delegate, client: inputClient)
                let currentInputClient = (inputClient as? InputClient) ?? client()
                activateServer(currentInputClient)
        }
        override func activateServer(_ sender: Any!) {
                super.activateServer(sender)
                UserLexicon.prepare()
                Engine.prepare()
                if inputStage.isBuffering {
                        clearBufferText()
                }
                if appContext.inputForm.isOptions {
                        appContext.updateInputForm()
                }
                screenWidth = NSScreen.main?.visibleFrame.size.width ?? window.screen?.visibleFrame.size.width ?? 1920
                currentClient = sender as? InputClient
                currentOrigin = currentClient?.position
                DispatchQueue.main.async { [weak self] in
                        self?.prepareMasterWindow()
                }
                DispatchQueue.main.async { [weak self] in
                        self?.currentClient?.overrideKeyboard(withKeyboardNamed: "com.apple.keylayout.ABC")
                }
        }
        override func deactivateServer(_ sender: Any!) {
                DispatchQueue.main.async { [weak self] in
                        self?.clearMasterWindow()
                }
                let windowCount: Int = NSApp.windows.count
                if windowCount > 20 {
                        NSRunningApplication.current.terminate()
                        NSApp.terminate(self)
                        exit(1)
                } else if windowCount > 10 {
                        _ = NSApp.windows.map({ $0.close() })
                } else {
                        _ = NSApp.windows.filter({ $0.identifier != window.identifier && $0.identifier?.rawValue != AppSettings.TypeDuckSettingsWindowIdentifier}).map({ $0.close() })
                }
                selectedCandidates = []
                if appContext.inputForm.isOptions {
                        clearOptionsViewHintText()
                        appContext.updateInputForm()
                }
                if inputStage.isBuffering {
                        let text: String = bufferText
                        clearBufferText()
                        (sender as? InputClient)?.insert(text)
                }
                super.deactivateServer(sender)
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
                didSet {
                        updateDisplayCandidates(.establish, highlight: .start)
                }
        }

        /// DisplayCandidates indices
        private lazy var indices: (first: Int, last: Int) = (0, 0)

        func updateDisplayCandidates(_ transformation: PageTransformation, highlight: Highlight) {
                let candidateCount: Int = candidates.count
                guard candidateCount > 0 else {
                        indices = (0, 0)
                        appContext.resetDisplayContext()
                        updateWindowFrame(.zero)
                        return
                }
                let pageSize: Int = AppSettings.candidatePageSize
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
                let shouldUpdateOrigin: Bool = appContext.isClean
                appContext.update(with: newDisplayCandidates, highlight: highlight)
                updateWindowFrame(shouldUpdateOrigin: shouldUpdateOrigin)
        }


        // MARK: - Candidate Suggestions

        private func suggest() {
                let processingText: String = bufferText.toneConverted()
                let segmentation = Segmentor.segment(text: processingText)
                let userLexiconCandidates: [Candidate] = UserLexicon.suggest(text: processingText, segmentation: segmentation).map({ origin -> Candidate in
                        guard let notation = Engine.fetchNotation(word: origin.text, romanization: origin.romanization) else { return origin }
                        return Candidate(text: origin.text, romanization: origin.romanization, input: origin.input, mark: origin.mark, notation: notation)
                })
                let needsSymbols: Bool = Options.isEmojiSuggestionsOn && selectedCandidates.isEmpty
                let asap: Bool = !(userLexiconCandidates.isEmpty)
                let engineCandidates: [Candidate] = Engine.suggest(text: processingText, segmentation: segmentation, needsSymbols: needsSymbols, asap: asap)
                let text2mark: String = {
                        if let mark = userLexiconCandidates.first?.mark { return mark }
                        let isLetterOnly: Bool = processingText.first(where: { $0.isSeparatorOrTone }) == nil
                        guard isLetterOnly else { return processingText.formattedForMark() }
                        let userInputTextCount: Int = processingText.count
                        if let firstCandidate = engineCandidates.first, firstCandidate.input.count == userInputTextCount { return firstCandidate.mark }
                        guard let bestScheme = segmentation.first else { return processingText.formattedForMark() }
                        let leadingLength: Int = bestScheme.length
                        let leadingText: String = bestScheme.map(\.text).joined(separator: " ")
                        guard leadingLength != userInputTextCount else { return leadingText }
                        let tailText = processingText.dropFirst(leadingLength)
                        return leadingText + " " + tailText
                }()
                mark(text: text2mark)
                candidates = (userLexiconCandidates + engineCandidates).map({ $0.transformed(to: Options.characterStandard) }).uniqued()
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
                        case PunctuationKey.quote.keyText:
                                return PunctuationKey.quote.symbols
                        case PunctuationKey.quote.shiftingKeyText:
                                return PunctuationKey.quote.shiftingSymbols
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
