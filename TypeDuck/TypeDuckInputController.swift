import SwiftUI
import InputMethodKit
import CoreIME

@MainActor
@objc(TypeDuckInputController)
final class TypeDuckInputController: IMKInputController, Sendable {

        // MARK: - Window, InputClient

        private lazy var window: NSPanel = CandidateWindow(level: nil)
        private func prepareWindow() {
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
                if let topAnchor = window.contentView?.topAnchor,
                   let bottomAnchor = window.contentView?.bottomAnchor,
                   let leadingAnchor = window.contentView?.leadingAnchor,
                   let trailingAnchor = window.contentView?.trailingAnchor {
                        NSLayoutConstraint.activate([
                                motherBoard.view.topAnchor.constraint(equalTo: topAnchor),
                                motherBoard.view.bottomAnchor.constraint(equalTo: bottomAnchor),
                                motherBoard.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                                motherBoard.view.trailingAnchor.constraint(equalTo: trailingAnchor)
                        ])
                }
                window.contentViewController?.addChild(motherBoard)
                window.orderFrontRegardless()
        }
        private func clearWindow() {
                _ = window.contentView?.subviews.map({ $0.removeFromSuperview() })
                _ = window.contentViewController?.children.map({ $0.removeFromParent() })
                window.setFrame(.zero, display: true)
        }
        private func updateWindowFrame(_ frame: CGRect? = nil) {
                window.setFrame(frame ?? windowFrame, display: true)
        }
        private var windowFrame: CGRect {
                let origin: CGPoint = {
                        guard let position = (currentPosition ?? currentClient?.position) else { return screenOrigin }
                        guard (position.x > screenOrigin.x) && (position.x < maxPointX) && (position.y > screenOrigin.y) && (position.y < maxPointY) else { return screenOrigin }
                        return position
                }()
                let viewSize: CGSize = {
                        guard let size = window.contentView?.subviews.first?.bounds.size, size.width > 44 else {
                                return CGSize(width: 800, height: 500)
                        }
                        return size
                }()
                let width: CGFloat = viewSize.width
                let height: CGFloat = viewSize.height
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

        private lazy var screenOrigin: CGPoint = NSScreen.main?.visibleFrame.origin ?? window.screen?.visibleFrame.origin ?? .zero
        private lazy var screenSize: CGSize = NSScreen.main?.visibleFrame.size ?? window.screen?.visibleFrame.size ?? CGSize(width: 1280, height: 800)
        private var maxPointX: CGFloat { screenOrigin.x + screenSize.width }
        private var maxPointY: CGFloat { screenOrigin.y + screenSize.height }
        private var maxPoint: CGPoint { CGPoint(x: maxPointX, y: maxPointY) }
        private lazy var currentPosition: CGPoint? = nil

        private typealias InputClient = (IMKTextInput & NSObjectProtocol)
        private lazy var currentClient: InputClient? = nil {
                didSet {
                        let origin: CGPoint = {
                                guard let position = currentClient?.position else { return screenOrigin }
                                guard (position.x > screenOrigin.x) && (position.x < maxPointX) && (position.y > screenOrigin.y) && (position.y < maxPointY) else { return screenOrigin }
                                return position
                        }()
                        let isRegularHorizontal: Bool = (maxPointX - origin.x) > 300
                        let isRegularVertical: Bool = (origin.y - screenOrigin.y) > 300
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
                let currentInputClient: InputClient? = (inputClient as? InputClient) ?? client()
                activateServer(currentInputClient)
        }
        override func activateServer(_ sender: Any!) {
                super.activateServer(sender)
                UserLexicon.prepare()
                Engine.prepare()
                nonisolated(unsafe) let nonIsolatedClient: InputClient? = (sender as? InputClient) ?? client()
                Task { @MainActor in
                        if inputStage.isBuffering {
                                clearBufferText()
                        }
                        if appContext.inputForm.isOptions {
                                appContext.updateInputForm()
                        }
                        screenOrigin = NSScreen.main?.visibleFrame.origin ?? window.screen?.visibleFrame.origin ?? .zero
                        screenSize = NSScreen.main?.visibleFrame.size ?? window.screen?.visibleFrame.size ?? CGSize(width: 1280, height: 800)
                        currentClient = nonIsolatedClient
                        currentPosition = nonIsolatedClient?.position
                        prepareWindow()
                }
        }
        override func deactivateServer(_ sender: Any!) {
                nonisolated(unsafe) let nonIsolatedClient: InputClient? = (sender as? InputClient) ?? client()
                Task { @MainActor in
                        clearWindow()
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
                                nonIsolatedClient?.insert(text)
                        }
                }
                super.deactivateServer(sender)
        }

        nonisolated(unsafe) private lazy var appContext: AppContext = AppContext()

        nonisolated(unsafe) private lazy var inputStage: InputStage = .standby

        private func clearBufferText() {
                bufferText = String.empty
        }
        private lazy var bufferText: String = .empty {
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
                        case (false, false):
                                inputStage = .ongoing
                        }
                }
                didSet {
                        switch bufferText.first {
                        case .none:
                                if AppSettings.isInputMemoryOn && selectedCandidates.isNotEmpty {
                                        let concatenated = selectedCandidates.joined()
                                        UserLexicon.handle(concatenated)
                                }
                                selectedCandidates = []
                                clearMarkedText()
                                candidates = []
                        case .some(let character) where character.isInvalidAnchor:
                                mark(text: bufferText)
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
                                        structureReverseLookup()
                                default:
                                        mark(text: bufferText)
                                }
                        default:
                                mark(text: bufferText)
                        }
                }
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
        private func markOptionsViewHintText() {
                guard !(inputStage.isBuffering) else { return }
                mark(text: String.zeroWidthSpace)
        }
        private func clearOptionsViewHintText() {
                guard !(inputStage.isBuffering) else { return }
                clearMarkedText()
        }


        // MARK: - Candidates

        /// Cached Candidate sequence for UserLexicon
        private lazy var selectedCandidates: [Candidate] = []

        private lazy var candidates: [Candidate] = [] {
                didSet {
                        updateDisplayCandidates(.establish, highlight: .start)
                }
        }

        /// DisplayCandidates indices
        private lazy var indices: (first: Int, last: Int) = (0, 0)

        private func updateDisplayCandidates(_ transformation: PageTransformation, highlight: Highlight) {
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
                appContext.update(with: newDisplayCandidates, highlight: highlight)
                updateWindowFrame()
        }


        // MARK: - Candidate Suggestions

        private func suggest() {
                let processingText: String = bufferText.toneConverted()
                let segmentation = Segmentor.segment(text: processingText)
                let userLexiconCandidates: [Candidate] = AppSettings.isInputMemoryOn ? UserLexicon.suggest(text: processingText, segmentation: segmentation).map({ Engine.embedNotations(for: $0) }) : []
                let needsSymbols: Bool = Options.isEmojiSuggestionsOn && selectedCandidates.isEmpty
                let asap: Bool = userLexiconCandidates.isNotEmpty
                let engineCandidates: [Candidate] = Engine.suggest(text: processingText, segmentation: segmentation, needsSymbols: needsSymbols, asap: asap)
                let text2mark: String = {
                        if let mark = userLexiconCandidates.first?.mark { return mark }
                        let isLetterOnly: Bool = processingText.first(where: { $0.isSeparatorOrTone }) == nil
                        guard isLetterOnly else { return processingText.formattedForMark() }
                        let userInputTextCount: Int = processingText.count
                        if let firstCandidate = engineCandidates.first, firstCandidate.input.count == userInputTextCount { return firstCandidate.mark }
                        guard let bestScheme = segmentation.first else { return processingText.formattedForMark() }
                        let leadingLength: Int = bestScheme.length
                        let leadingText: String = bestScheme.map(\.text).joined(separator: String.space)
                        guard leadingLength != userInputTextCount else { return leadingText }
                        let tailText = processingText.dropFirst(leadingLength)
                        return leadingText + String.space + tailText
                }()
                mark(text: text2mark)
                candidates = (userLexiconCandidates + engineCandidates).map({ $0.transformed(to: Options.characterStandard) }).uniqued()
        }
        private func pinyinReverseLookup() {
                let text: String = String(bufferText.dropFirst(2))
                guard text.isNotEmpty else {
                        mark(text: bufferText)
                        candidates = []
                        return
                }
                let schemes: [[String]] = PinyinSegmentor.segment(text: text)
                let suggestions: [Candidate] = Engine.pinyinReverseLookup(text: text, schemes: schemes)
                let tailText2Mark: String = {
                        if let firstCandidate = suggestions.first, firstCandidate.input.count == text.count { return firstCandidate.mark }
                        guard let bestScheme = schemes.first else { return text }
                        let leadingLength: Int = bestScheme.summedLength
                        let leadingText: String = bestScheme.joined(separator: String.space)
                        guard leadingLength != text.count else { return leadingText }
                        let tailText = text.dropFirst(leadingLength)
                        return leadingText + String.space + tailText
                }()
                let head = bufferText.prefix(2) + String.space
                let text2mark: String = head + tailText2Mark
                mark(text: text2mark)
                candidates = suggestions.map({ $0.transformed(to: Options.characterStandard) }).uniqued()
        }
        private func cangjieReverseLookup() {
                let text: String = String(bufferText.dropFirst(2))
                let converted = text.compactMap({ CharacterStandard.cangjie(of: $0) })
                let isValidSequence: Bool = converted.isNotEmpty && (converted.count == text.count)
                if isValidSequence {
                        mark(text: String(converted))
                        let lookup: [Candidate] = Engine.cangjieReverseLookup(text: text, variant: AppSettings.cangjieVariant)
                        candidates = lookup.map({ $0.transformed(to: Options.characterStandard) }).uniqued()
                } else {
                        mark(text: bufferText)
                        candidates = []
                }
        }
        private func strokeReverseLookup() {
                let text: String = String(bufferText.dropFirst(2))
                let transformed: String = CharacterStandard.strokeTransform(text)
                let converted = transformed.compactMap({ CharacterStandard.stroke(of: $0) })
                let isValidSequence: Bool = converted.isNotEmpty && (converted.count == text.count)
                if isValidSequence {
                        mark(text: String(converted))
                        let lookup: [Candidate] = Engine.strokeReverseLookup(text: transformed)
                        candidates = lookup.map({ $0.transformed(to: Options.characterStandard) }).uniqued()
                } else {
                        mark(text: bufferText)
                        candidates = []
                }
        }

        /// LoengFan Reverse Lookup. 拆字、兩分反查. 例如 木 + 木 = 林: mukmuk
        private func structureReverseLookup() {
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
                        let leadingText: String = bestScheme.map(\.text).joined(separator: String.space)
                        guard leadingLength != text.count else { return leadingText }
                        let tailText = text.dropFirst(leadingLength)
                        return leadingText + String.space + tailText
                }()
                let head = bufferText.prefix(2) + String.space
                let text2mark: String = head + tailMarkedText
                mark(text: text2mark)
                let lookup: [Candidate] = Engine.structureReverseLookup(text: text, input: bufferText, segmentation: segmentation)
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

        override func recognizedEvents(_ sender: Any!) -> Int {
                let masks: NSEvent.EventTypeMask = [.keyDown]
                return Int(masks.rawValue)
        }
        override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
                guard let event = event else { return false }
                let modifiers = event.modifierFlags
                let shouldIgnoreCurrentEvent: Bool = modifiers.contains(.command) || modifiers.contains(.option)
                guard !shouldIgnoreCurrentEvent else { return false }
                let currentInputForm: InputForm = appContext.inputForm
                let isBuffering: Bool = inputStage.isBuffering
                let code: UInt16 = event.keyCode
                lazy var hasControlShiftModifiers: Bool = false
                lazy var isEventHandled: Bool = true
                switch modifiers {
                case [.control, .shift], .control:
                        switch code {
                        case KeyCode.Symbol.VK_COMMA:
                                return false // Should be handled by NSMenu
                        case KeyCode.Symbol.VK_BACKQUOTE:
                                hasControlShiftModifiers = true
                                isEventHandled = true
                        case KeyCode.Special.VK_BACKWARD_DELETE, KeyCode.Special.VK_FORWARD_DELETE:
                                guard isBuffering else { return false }
                                hasControlShiftModifiers = true
                                isEventHandled = true
                        case KeyCode.Alphabet.VK_U:
                                guard isBuffering || currentInputForm.isOptions else { return false }
                                hasControlShiftModifiers = true
                                isEventHandled = true
                        case let value where KeyCode.numberSet.contains(value):
                                hasControlShiftModifiers = true
                                isEventHandled = true
                        default:
                                return false
                        }
                case .shift:
                        let shouldHandle: Bool = (code != KeyCode.Special.VK_RETURN)
                        guard shouldHandle else { return false }
                        isEventHandled = true
                case .capsLock, .function, .help:
                        return false
                default:
                        guard !(modifiers.contains(.deviceIndependentFlagsMask)) else { return false }
                }
                switch code.representative {
                case .alphabet(_):
                        switch currentInputForm {
                        case .cantonese:
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .number(_):
                        switch currentInputForm {
                        case .cantonese:
                                guard hasControlShiftModifiers || isBuffering else { return false }
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .keypadNumber(_):
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return false }
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .arrow(_):
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return false }
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .backquote where hasControlShiftModifiers:
                        isEventHandled = true
                case .backquote, .punctuation(_):
                        switch currentInputForm {
                        case .cantonese:
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .separator:
                        switch currentInputForm {
                        case .cantonese:
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .return:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return false }
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .backspace, .forwardDelete:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return false }
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .escape, .clear:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return false }
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .space:
                        isEventHandled = true
                case .tab:
                        switch currentInputForm {
                        case .cantonese:
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .previousPage:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return false }
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .nextPage:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return false }
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .other:
                        switch code {
                        case KeyCode.Special.VK_HOME where isBuffering:
                                isEventHandled = true
                        default:
                                return false
                        }
                }
                nonisolated(unsafe) let nonIsolatedClient: InputClient? = (sender as? InputClient)
                let isShifting: Bool = (modifiers == .shift)
                Task { @MainActor in
                        process(keyCode: code, client: nonIsolatedClient, hasControlShiftModifiers: hasControlShiftModifiers, isShifting: isShifting)
                }
                return isEventHandled
        }

        private func process(keyCode: UInt16, client: InputClient?, hasControlShiftModifiers: Bool, isShifting: Bool) {
                if let position = client?.position {
                        currentPosition = position
                }
                let oldClientID = currentClient?.uniqueClientIdentifierString()
                let clientID = client?.uniqueClientIdentifierString()
                if clientID != oldClientID {
                        currentClient = client
                }
                let currentInputForm: InputForm = appContext.inputForm
                let isBuffering = inputStage.isBuffering
                switch keyCode.representative {
                case .alphabet(_) where hasControlShiftModifiers && isBuffering && (keyCode == KeyCode.Alphabet.VK_U):
                        clearBufferText()
                case .alphabet(let letter):
                        switch currentInputForm {
                        case .cantonese:
                                let text: String = isShifting ? letter.uppercased() : letter
                                bufferText += text
                        case .transparent:
                                return
                        case .options:
                                return
                        }
                case .number(let number):
                        let index: Int = (number == 0) ? 9 : (number - 1)
                        switch currentInputForm {
                        case .cantonese:
                                if isBuffering {
                                        guard let selectedItem = appContext.displayCandidates.fetch(index) else { return }
                                        let text = selectedItem.candidate.text
                                        currentClient?.insert(text)
                                        aftercareSelection(selectedItem)
                                } else {
                                        if hasControlShiftModifiers {
                                                handleOptions(index)
                                        } else {
                                                switch Options.characterForm {
                                                case .halfWidth:
                                                        let shouldInsertCantoneseSymbol: Bool = isShifting && Options.punctuationForm.isCantoneseMode
                                                        guard shouldInsertCantoneseSymbol else { return }
                                                        let text: String = KeyCode.shiftingSymbol(of: number)
                                                        currentClient?.insert(text)
                                                case .fullWidth:
                                                        let text: String = isShifting ? KeyCode.shiftingSymbol(of: number) : "\(number)"
                                                        let fullWidthText: String = text.fullWidth()
                                                        currentClient?.insert(fullWidthText)
                                                }
                                        }
                                }
                        case .transparent:
                                if hasControlShiftModifiers {
                                        handleOptions(index)
                                }
                        case .options:
                                handleOptions(index)
                        }
                case .keypadNumber(let number):
                        let isStrokeReverseLookup: Bool = currentInputForm.isCantonese && bufferText.hasPrefix("x")
                        guard isStrokeReverseLookup else { return }
                        bufferText += "\(number)"
                case .arrow(let direction):
                        switch direction {
                        case .up:
                                switch currentInputForm {
                                case .cantonese:
                                        guard isBuffering else { return }
                                        if appContext.isHighlightingStart {
                                                updateDisplayCandidates(.previousPage, highlight: .end)
                                        } else {
                                                appContext.decreaseHighlightedIndex()
                                        }
                                case .transparent:
                                        return
                                case .options:
                                        appContext.decreaseOptionsHighlightedIndex()
                                }
                        case .down:
                                switch currentInputForm {
                                case .cantonese:
                                        guard isBuffering else { return }
                                        if appContext.isHighlightingEnd {
                                                updateDisplayCandidates(.nextPage, highlight: .start)
                                        } else {
                                                appContext.increaseHighlightedIndex()
                                        }
                                case .transparent:
                                        return
                                case .options:
                                        appContext.increaseOptionsHighlightedIndex()
                                }
                        case .left:
                                switch currentInputForm {
                                case .cantonese:
                                        guard isBuffering else { return }
                                        updateDisplayCandidates(.previousPage, highlight: .unchanged)
                                case .transparent:
                                        return
                                case .options:
                                        return
                                }
                        case .right:
                                switch currentInputForm {
                                case .cantonese:
                                        guard isBuffering else { return }
                                        updateDisplayCandidates(.nextPage, highlight: .unchanged)
                                case .transparent:
                                        return
                                case .options:
                                        return
                                }
                        }
                case .backquote where hasControlShiftModifiers:
                        switch currentInputForm {
                        case .cantonese, .transparent:
                                markOptionsViewHintText()
                                appContext.updateInputForm(to: .options)
                                updateWindowFrame()
                        case .options:
                                handleOptions(-1)
                        }
                case .backquote:
                        guard currentInputForm.isCantonese else { return }
                        guard !isBuffering else { return }
                        guard Options.punctuationForm.isCantoneseMode else { return }
                        let symbolText: String = isShifting ? PunctuationKey.backquote.shiftingKeyText : PunctuationKey.backquote.keyText
                        bufferText = symbolText
                case .punctuation(let punctuationKey):
                        guard currentInputForm.isCantonese else { return }
                        guard !isBuffering else {
                                switch punctuationKey {
                                case .bracketLeft, .comma, .minus:
                                        updateDisplayCandidates(.previousPage, highlight: .unchanged)
                                case .bracketRight, .period, .equal:
                                        updateDisplayCandidates(.nextPage, highlight: .unchanged)
                                default:
                                        return
                                }
                                return
                        }
                        guard Options.punctuationForm.isCantoneseMode else { return }
                        if isShifting {
                                if let symbol = punctuationKey.instantShiftingSymbol {
                                        currentClient?.insert(symbol)
                                } else {
                                        bufferText = punctuationKey.shiftingKeyText
                                }
                        } else {
                                if let symbol = punctuationKey.instantSymbol {
                                        currentClient?.insert(symbol)
                                } else {
                                        bufferText = punctuationKey.keyText
                                }
                        }
                case .separator:
                        switch currentInputForm {
                        case .cantonese:
                                if isBuffering {
                                        bufferText += "'"
                                } else {
                                        guard Options.punctuationForm.isCantoneseMode else { return }
                                        let text: String = isShifting ? PunctuationKey.quote.shiftingKeyText : PunctuationKey.quote.keyText
                                        bufferText = text
                                }
                        case .transparent:
                                return
                        case .options:
                                return
                        }
                case .return:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return }
                                passBuffer()
                        case .transparent:
                                return
                        case .options:
                                handleOptions()
                        }
                case .backspace:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return }
                                guard hasControlShiftModifiers else {
                                        bufferText = String(bufferText.dropLast())
                                        return
                                }
                                guard candidates.isNotEmpty else { return }
                                let index = appContext.highlightedIndex
                                guard let candidate = appContext.displayCandidates.fetch(index)?.candidate else { return }
                                guard candidate.isCantonese else { return }
                                UserLexicon.removeItem(candidate: candidate)
                        case .transparent:
                                return
                        case .options:
                                handleOptions(-1)
                        }
                case .forwardDelete:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return }
                                guard hasControlShiftModifiers else { return }
                                guard candidates.isNotEmpty else { return }
                                let index = appContext.highlightedIndex
                                guard let candidate = appContext.displayCandidates.fetch(index)?.candidate else { return }
                                guard candidate.isCantonese else { return }
                                UserLexicon.removeItem(candidate: candidate)
                        case .transparent:
                                return
                        case .options:
                                handleOptions(-1)
                        }
                case .escape, .clear:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return }
                                clearBufferText()
                        case .transparent:
                                return
                        case .options:
                                handleOptions(-1)
                        }
                case .space:
                        switch currentInputForm {
                        case .cantonese:
                                if candidates.isEmpty {
                                        passBuffer()
                                        let shouldInsertFullWidthSpace: Bool = isShifting || (Options.characterForm == .fullWidth)
                                        let text: String = shouldInsertFullWidthSpace ? String.fullWidthSpace : String.space
                                        currentClient?.insert(text)
                                } else {
                                        let index = appContext.highlightedIndex
                                        guard let selectedItem = appContext.displayCandidates.fetch(index) else { return }
                                        let text = selectedItem.candidate.text
                                        currentClient?.insert(text)
                                        aftercareSelection(selectedItem)
                                }
                        case .transparent:
                                return
                        case .options:
                                handleOptions()
                        }
                case .tab:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return }
                                if isShifting {
                                        if appContext.isHighlightingStart {
                                                updateDisplayCandidates(.previousPage, highlight: .end)
                                        } else {
                                                appContext.decreaseHighlightedIndex()
                                        }
                                } else {
                                        if appContext.isHighlightingEnd {
                                                updateDisplayCandidates(.nextPage, highlight: .start)
                                        } else {
                                                appContext.increaseHighlightedIndex()
                                        }
                                }
                        case .transparent:
                                return
                        case .options:
                                if isShifting {
                                        appContext.decreaseOptionsHighlightedIndex()
                                } else {
                                        appContext.increaseOptionsHighlightedIndex()
                                }
                        }
                case .previousPage:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return }
                                updateDisplayCandidates(.previousPage, highlight: .unchanged)
                        case .transparent:
                                return
                        case .options:
                                return
                        }
                case .nextPage:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return }
                                updateDisplayCandidates(.nextPage, highlight: .unchanged)
                        case .transparent:
                                return
                        case .options:
                                return
                        }
                case .other:
                        switch keyCode {
                        case KeyCode.Special.VK_HOME:
                                let shouldJump2FirstPage: Bool = currentInputForm.isCantonese && candidates.isNotEmpty
                                guard shouldJump2FirstPage else { return }
                                updateDisplayCandidates(.establish, highlight: .start)
                        default:
                                return
                        }
                }
        }

        private func passBuffer() {
                guard inputStage.isBuffering else { return }
                let text: String = Options.characterForm == .halfWidth ? bufferText : bufferText.fullWidth()
                currentClient?.insert(text)
                clearBufferText()
        }
        private func handleOptions(_ index: Int? = nil) {
                let selectedIndex: Int = index ?? appContext.optionsHighlightedIndex
                defer {
                        clearOptionsViewHintText()
                        appContext.updateInputForm()
                        let frame: CGRect? = candidates.isEmpty ? .zero : nil
                        updateWindowFrame(frame)
                }
                switch selectedIndex {
                case -1:
                        break
                case 2:
                        Options.updateCharacterForm(to: .halfWidth)
                case 3:
                        Options.updateCharacterForm(to: .fullWidth)
                case 4:
                        Options.updatePunctuationForm(to: .cantonese)
                case 5:
                        Options.updatePunctuationForm(to: .english)
                case 6:
                        Options.updateEmojiSuggestions(to: true)
                case 7:
                        Options.updateEmojiSuggestions(to: false)
                default:
                        break
                }
                let newVariant: CharacterStandard? = {
                        switch selectedIndex {
                        case 0:
                                return .traditional
                        case 1:
                                return .simplified
                        default:
                                return nil
                        }
                }()
                guard let newVariant, newVariant != Options.characterStandard else { return }
                Options.updateCharacterStandard(to: newVariant)
        }
        private func aftercareSelection(_ selected: DisplayCandidate) {
                let candidate = candidates.fetch(selected.candidateIndex) ?? candidates.first(where: { $0 == selected.candidate })
                guard let candidate, candidate.isCantonese else {
                        clearBufferText()
                        return
                }
                switch bufferText.first {
                case .none:
                        return
                case .some(.backtick):
                        selectedCandidates = []
                        let leadingCount: Int = candidate.input.count + 2
                        if bufferText.count > leadingCount {
                                let head = bufferText.prefix(2)
                                let tail = bufferText.dropFirst(leadingCount)
                                bufferText = String(head + tail)
                        } else {
                                clearBufferText()
                        }
                case .some(let character) where !(character.isBasicLatinLetter):
                        selectedCandidates = []
                        clearBufferText()
                default:
                        selectedCandidates.append(candidate)
                        let inputCount: Int = candidate.input.replacingOccurrences(of: "(4|5|6)", with: "RR", options: .regularExpression).count
                        var tail = bufferText.dropFirst(inputCount)
                        while tail.hasPrefix("'") {
                                tail = tail.dropFirst()
                        }
                        bufferText = String(tail)
                }
        }


        // MARK: - Menu

        override func menu() -> NSMenu! {
                let menuTitle: String = String(localized: "Menu.Title")
                let menu = NSMenu(title: menuTitle)

                let settingsTitle: String = String(localized: "Menu.Settings")
                let settings = NSMenuItem(title: settingsTitle, action: #selector(openSettings), keyEquivalent: ",")
                settings.keyEquivalentModifierMask = [.control, .shift]
                menu.addItem(settings)

                // TODO: - Check for Updates
                let checkForUpdatesTitle: String = String(localized: "Menu.CheckForUpdates")
                _ = NSMenuItem(title: checkForUpdatesTitle, action: #selector(openSettings), keyEquivalent: "")
                // menu.addItem(checkForUpdates)

                let helpTitle: String = String(localized: "Menu.Help")
                let help = NSMenuItem(title: helpTitle, action: #selector(openHelp), keyEquivalent: "")
                menu.addItem(help)

                let aboutTitle: String = String(localized: "Menu.About")
                let about = NSMenuItem(title: aboutTitle, action: #selector(openAbout), keyEquivalent: "")
                menu.addItem(about)

                return menu
        }
        @objc private func openSettings() {
                AppSettings.updateSelectedSettingsSidebarRow(to: .general)
                displaySettingsWindow()
        }
        @objc private func openHelp() {
                AppSettings.updateSelectedSettingsSidebarRow(to: .help)
                displaySettingsWindow()
        }
        @objc private func openAbout() {
                AppSettings.updateSelectedSettingsSidebarRow(to: .about)
                displaySettingsWindow()
        }
        private func displaySettingsWindow() {
                let windowIdentifiers: [String] = NSApp.windows.compactMap(\.identifier?.rawValue)
                let shouldOpenNewWindow: Bool = windowIdentifiers.notContains(AppSettings.TypeDuckSettingsWindowIdentifier)
                guard shouldOpenNewWindow else { return }
                let frame: CGRect = settingsWindowFrame()
                let window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: true)
                window.identifier = NSUserInterfaceItemIdentifier(rawValue: AppSettings.TypeDuckSettingsWindowIdentifier)
                window.title = String(localized: "Settings.Window.Title")
                let visualEffectView = NSVisualEffectView()
                visualEffectView.material = .sidebar
                visualEffectView.blendingMode = .behindWindow
                visualEffectView.state = .active
                window.contentView = visualEffectView
                let hostingController = NSHostingController(rootView: SettingsView())
                window.contentView?.addSubview(hostingController.view)
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                if let topAnchor = window.contentView?.topAnchor,
                   let bottomAnchor = window.contentView?.bottomAnchor,
                   let leadingAnchor = window.contentView?.leadingAnchor,
                   let trailingAnchor = window.contentView?.trailingAnchor {
                        NSLayoutConstraint.activate([
                                hostingController.view.topAnchor.constraint(equalTo: topAnchor),
                                hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
                                hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                                hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor)
                        ])
                }
                window.contentViewController?.addChild(hostingController)
                window.orderFrontRegardless()
                window.setFrame(frame, display: true)
                NSApp.activate(ignoringOtherApps: true)
        }
        private func settingsWindowFrame() -> CGRect {
                let screenOrigin: CGPoint = NSScreen.main?.visibleFrame.origin ?? .zero
                let screenWidth: CGFloat = NSScreen.main?.visibleFrame.size.width ?? 1280
                let screenHeight: CGFloat = NSScreen.main?.visibleFrame.size.height ?? 800
                let x: CGFloat = screenOrigin.x + (screenWidth / 4.0)
                let y: CGFloat = screenOrigin.y + (screenHeight / 5.0)
                let width: CGFloat = screenWidth / 2.0
                let height: CGFloat = (screenHeight / 5.0) * 3.0
                return CGRect(x: x, y: y, width: width, height: height)
        }
}
