import SwiftUI
import InputMethodKit
import CoreIME

@MainActor
final class TypeDuckInputController: IMKInputController, Sendable {

        // MARK: - Window, InputClient

        private lazy var window: NSPanel = CandidateWindow(level: nil)
        private func prepareWindow() {
                window.contentViewController = nil
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
                window.contentViewController = NSHostingController(rootView: MotherBoard().environmentObject(appContext))
                window.orderFrontRegardless()
        }
        private func clearWindow() {
                window.contentViewController = nil
                window.setFrame(.zero, display: true)
        }
        private func updateWindowFrame(_ frame: CGRect? = nil) {
                window.setFrame(frame ?? windowFrame, display: true)
        }
        private var windowFrame: CGRect {
                let quadrant = appContext.quadrant
                let position: CGPoint = {
                        guard let cursorBlock = currentCursorBlock ?? currentClient?.cursorBlock else { return screenOrigin }
                        let x: CGFloat = quadrant.isNegativeHorizontal ? cursorBlock.origin.x : cursorBlock.maxX
                        let y: CGFloat = quadrant.isNegativeVertical ? cursorBlock.origin.y : cursorBlock.maxY
                        guard (x > screenOrigin.x) && (x < maxPointX) && (y > screenOrigin.y) && (y < maxPointY) else { return screenOrigin }
                        return CGPoint(x: x, y: y)
                }()
                let width: CGFloat = switch quadrant {
                case .upperRight:
                        CGFloat.zero
                case .upperLeft:
                        800
                case .bottomLeft:
                        800
                case .bottomRight:
                        44
                }
                let height: CGFloat = switch quadrant {
                case .upperRight:
                        CGFloat.zero
                case .upperLeft:
                        CGFloat.zero
                case .bottomLeft:
                        44
                case .bottomRight:
                        44
                }
                let x: CGFloat = quadrant.isNegativeHorizontal ? (position.x - width) : position.x
                let y: CGFloat = quadrant.isNegativeVertical ? (position.y - height) : position.y
                return CGRect(x: x, y: y, width: width, height: height)
        }

        private lazy var screenOrigin: CGPoint = NSScreen.main?.visibleFrame.origin ?? window.screen?.visibleFrame.origin ?? .zero
        private lazy var screenSize: CGSize = NSScreen.main?.visibleFrame.size ?? window.screen?.visibleFrame.size ?? CGSize(width: 1280, height: 800)
        private var maxPointX: CGFloat { screenOrigin.x + screenSize.width }
        private var maxPointY: CGFloat { screenOrigin.y + screenSize.height }
        private var maxPoint: CGPoint { CGPoint(x: maxPointX, y: maxPointY) }
        private lazy var currentCursorBlock: CGRect? = nil
        private func updateCurrentCursorBlock(to rect: CGRect?) {
                guard let point = rect?.origin else { return }
                guard (point.x > screenOrigin.x) && (point.x < maxPointX) && (point.y > screenOrigin.y) && (point.y < maxPointY) else { return }
                currentCursorBlock = rect
        }

        private typealias InputClient = (IMKTextInput & NSObjectProtocol)
        private lazy var currentClient: InputClient? = nil {
                didSet {
                        let position: CGPoint = {
                                guard let point = currentClient?.cursorBlock.origin else { return screenOrigin }
                                guard (point.x > screenOrigin.x) && (point.x < maxPointX) && (point.y > screenOrigin.y) && (point.y < maxPointY) else { return screenOrigin }
                                return point
                        }()
                        let isPositiveHorizontal: Bool = (maxPointX - position.x) > 300
                        let isPositiveVertical: Bool = (position.y - screenOrigin.y) < 300
                        let newQuadrant: Quadrant = switch (isPositiveHorizontal, isPositiveVertical) {
                        case (true, true):
                                Quadrant.upperRight
                        case (false, true):
                                Quadrant.upperLeft
                        case (true, false):
                                Quadrant.bottomRight
                        case (false, false):
                                Quadrant.bottomLeft
                        }
                        if newQuadrant != appContext.quadrant {
                                appContext.updateQuadrant(to: newQuadrant)
                        }
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
                nonisolated(unsafe) let client: InputClient? = (sender as? InputClient) ?? client()
                Task { @MainActor in
                        UserLexicon.prepare()
                        Engine.prepare()
                        if inputStage.isBuffering {
                                clearBufferText()
                        }
                        if inputForm.isOptions {
                                updateInputForm()
                        }
                        screenOrigin = NSScreen.main?.visibleFrame.origin ?? window.screen?.visibleFrame.origin ?? .zero
                        screenSize = NSScreen.main?.visibleFrame.size ?? window.screen?.visibleFrame.size ?? CGSize(width: 1280, height: 800)
                        currentClient = client
                        updateCurrentCursorBlock(to: client?.cursorBlock)
                        prepareWindow()
                }
        }
        override func deactivateServer(_ sender: Any!) {
                nonisolated(unsafe) let client: InputClient? = (sender as? InputClient) ?? client()
                Task { @MainActor in
                        clearWindow()
                        selectedCandidates = []
                        if inputForm.isOptions {
                                updateInputForm()
                        }
                        if inputStage.isBuffering {
                                let text: String = bufferText
                                clearBufferText()
                                client?.insertText(text as NSString, replacementRange: replacementRange())
                        }
                        clearMarkedText()
                        let windowCount = NSApp.windows.count
                        if windowCount > 20 {
                                NSRunningApplication.current.terminate()
                                NSApp.terminate(self)
                                exit(1)
                        } else if windowCount > 10 {
                                _ = NSApp.windows.map({ $0.close() })
                        } else {
                                _ = NSApp.windows.filter({ $0.identifier != window.identifier && $0.identifier?.rawValue != AppSettings.TypeDuckSettingsWindowIdentifier }).map({ $0.close() })
                        }
                }
                super.deactivateServer(sender)
        }

        private lazy var appContext: AppContext = AppContext()

        nonisolated(unsafe) private lazy var inputForm: InputForm = InputForm.matchInputMethodMode()
        func updateInputForm(to form: InputForm? = nil) {
                let newForm = form ?? InputForm.matchInputMethodMode()
                inputForm = newForm
                appContext.updateInputForm(to: newForm)
        }

        nonisolated(unsafe) private lazy var inputStage: InputStage = .standby

        private func clearBufferText() { bufferText = String.empty }
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

        private func insert(_ text: String) {
                // let range = NSRange(location: NSNotFound, length: 0)
                currentClient?.insertText(text as NSString, replacementRange: replacementRange())
        }
        private func mark(text: String) {
                let attributedText = NSAttributedString(string: text, attributes: markAttributes)
                let selectionRange = NSRange(location: text.utf16.count, length: 0)
                currentClient?.setMarkedText(attributedText, selectionRange: selectionRange, replacementRange: replacementRange())
        }
        private func clearMarkedText() {
                let attributedText = NSAttributedString(string: String(), attributes: markAttributes)
                let selectionRange = NSRange(location: 0, length: 0)
                currentClient?.setMarkedText(attributedText, selectionRange: selectionRange, replacementRange: replacementRange())
        }
        private lazy var markAttributes: [NSAttributedString.Key: Any] = {
                let attributes = mark(forStyle: kTSMHiliteSelectedConvertedText, at: replacementRange())
                return (attributes as? [NSAttributedString.Key: Any]) ?? [.underlineStyle: NSUnderlineStyle.thick.rawValue]
        }()
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
                updateWindowFrame()
                let newDisplayCandidates = (firstIndex..<bound).map({ index -> DisplayCandidate in
                        return DisplayCandidate(candidate: candidates[index], candidateIndex: index)
                })
                appContext.update(with: newDisplayCandidates, highlight: highlight)
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
                let symbols: [PunctuationSymbol] = switch bufferText {
                case PunctuationKey.comma.shiftingKeyText:
                        PunctuationKey.comma.shiftingSymbols
                case PunctuationKey.period.shiftingKeyText:
                        PunctuationKey.period.shiftingSymbols
                case PunctuationKey.slash.keyText:
                        PunctuationKey.slash.symbols
                case PunctuationKey.quote.keyText:
                        PunctuationKey.quote.symbols
                case PunctuationKey.quote.shiftingKeyText:
                        PunctuationKey.quote.shiftingSymbols
                case PunctuationKey.bracketLeft.shiftingKeyText:
                        PunctuationKey.bracketLeft.shiftingSymbols
                case PunctuationKey.bracketRight.shiftingKeyText:
                        PunctuationKey.bracketRight.shiftingSymbols
                case PunctuationKey.backSlash.shiftingKeyText:
                        PunctuationKey.backSlash.shiftingSymbols
                case PunctuationKey.backquote.keyText:
                        PunctuationKey.backquote.symbols
                case PunctuationKey.backquote.shiftingKeyText:
                        PunctuationKey.backquote.shiftingSymbols
                default:
                        []
                }
                candidates = symbols.map({ Candidate(text: $0.symbol, comment: $0.comment, secondaryComment: $0.secondaryComment, input: bufferText) })
        }


        // MARK: - Handle Event

        override func recognizedEvents(_ sender: Any!) -> Int {
                let masks: NSEvent.EventTypeMask = [.keyDown]
                return Int(masks.rawValue)
        }
        override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
                guard let event = event else { return false }
                let modifiers = event.modifierFlags
                let shouldIgnoreCurrentEvent: Bool = modifiers.contains(.command) || modifiers.contains(.option)
                guard !shouldIgnoreCurrentEvent else { return false }
                let currentInputForm: InputForm = inputForm
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
                        isEventHandled = true
                case .capsLock, .function, .help:
                        return false
                default:
                        guard !(modifiers.contains(.deviceIndependentFlagsMask)) else { return false }
                }
                let isShifting: Bool = (modifiers == .shift)
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
                        switch currentInputForm {
                        case .cantonese:
                                let shouldHandle: Bool = isBuffering || isShifting
                                guard shouldHandle else { return false }
                                isEventHandled = true
                        case .transparent:
                                return false
                        case .options:
                                isEventHandled = true
                        }
                case .tab:
                        switch currentInputForm {
                        case .cantonese:
                                guard isBuffering else { return false }
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
                nonisolated(unsafe) let client: InputClient? = (sender as? InputClient)
                if !isBuffering && isEventHandled {
                        let attributes: [NSAttributedString.Key: Any] = (mark(forStyle: kTSMHiliteSelectedConvertedText, at: replacementRange()) as? [NSAttributedString.Key: Any]) ?? [.underlineStyle: NSUnderlineStyle.thick.rawValue]
                        let attributedText = NSAttributedString(string: String.zeroWidthSpace, attributes: attributes)
                        let selectionRange = NSRange(location: String.zeroWidthSpace.utf16.count, length: 0)
                        let replacementRange = NSRange(location: NSNotFound, length: 0)
                        client?.setMarkedText(attributedText, selectionRange: selectionRange, replacementRange: replacementRange)
                }
                Task { @MainActor in
                        process(keyCode: code, client: client, hasControlShiftModifiers: hasControlShiftModifiers, isShifting: isShifting)
                }
                return isEventHandled
        }
        private func process(keyCode: UInt16, client: InputClient?, hasControlShiftModifiers: Bool, isShifting: Bool) {
                updateCurrentCursorBlock(to: client?.cursorBlock)
                let oldClientID = currentClient?.uniqueClientIdentifierString()
                let clientID = client?.uniqueClientIdentifierString()
                if clientID != oldClientID {
                        currentClient = client
                }
                let currentInputForm: InputForm = inputForm
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
                                        insert(text)
                                        aftercareSelection(selectedItem)
                                } else if hasControlShiftModifiers {
                                        handleOptions(index)
                                } else {
                                        let text: String = "\(number)"
                                        let convertedText: String = Options.characterForm.isHalfWidth ? text : text.fullWidth()
                                        switch Options.punctuationForm {
                                        case .cantonese:
                                                let insertion: String? = isShifting ? Representative.shiftingCantoneseSymbol(of: number) : convertedText
                                                insertion.flatMap(insert(_:))
                                        case .english:
                                                let insertion: String? = isShifting ? Representative.shiftingSymbol(of: number) : convertedText
                                                insertion.flatMap(insert(_:))
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
                                updateInputForm(to: .options)
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
                                        insert(symbol)
                                } else {
                                        bufferText = punctuationKey.shiftingKeyText
                                }
                        } else {
                                if let symbol = punctuationKey.instantSymbol {
                                        insert(symbol)
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
                                let romanization: String? = {
                                        guard isShifting && candidates.isNotEmpty else { return nil }
                                        let index = appContext.highlightedIndex
                                        guard let candidate = appContext.displayCandidates.fetch(index)?.candidate else { return nil }
                                        guard candidate.isCantonese else { return nil }
                                        return candidate.romanization
                                }()
                                if let romanization {
                                        insert(romanization)
                                        clearBufferText()
                                } else {
                                        passBuffer()
                                }
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
                                if candidates.isNotEmpty {
                                        let index = appContext.highlightedIndex
                                        guard let selectedItem = appContext.displayCandidates.fetch(index) else { return }
                                        let text = selectedItem.candidate.text
                                        insert(text)
                                        aftercareSelection(selectedItem)
                                } else if isBuffering {
                                        passBuffer()
                                } else if isShifting || Options.characterForm.isFullWidth {
                                        insert(String.fullWidthSpace)
                                } else {
                                        insert(String.space)
                                }
                        case .transparent:
                                insert(String.space)
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
                insert(text)
                clearBufferText()
        }
        private func handleOptions(_ index: Int? = nil) {
                let selectedIndex: Int = index ?? appContext.optionsHighlightedIndex
                defer {
                        clearOptionsViewHintText()
                        updateInputForm()
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


        // MARK: - macOS Menu

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
                let shouldOpenNewWindow: Bool = NSApp.windows.compactMap(\.identifier?.rawValue).notContains(AppSettings.TypeDuckSettingsWindowIdentifier)
                guard shouldOpenNewWindow else { return }
                let frame: CGRect = settingsWindowFrame()
                let settingsWindow = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: true)
                settingsWindow.identifier = NSUserInterfaceItemIdentifier(rawValue: AppSettings.TypeDuckSettingsWindowIdentifier)
                settingsWindow.title = String(localized: "Settings.Window.Title")
                settingsWindow.toolbarStyle = .unifiedCompact
                settingsWindow.contentViewController = NSHostingController(rootView: SettingsView())
                settingsWindow.orderFrontRegardless()
                settingsWindow.setFrame(frame, display: true)
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
