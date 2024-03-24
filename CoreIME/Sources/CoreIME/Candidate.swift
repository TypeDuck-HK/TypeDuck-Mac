public enum CandidateType: Int {

        case cantonese

        /// Plain text. Examples: iPad, macOS
        case text

        case emoji

        case emojiSequence

        /// Note that `text.count == 1` not always true
        case symbol

        case symbolSequence

        /// macOS Keyboard composed text. Mainly for PunctuationKey.
        case compose
}

public struct Candidate: Hashable {

        /// Candidate Type
        public let type: CandidateType

        /// Candidate text for display.
        ///
        /// Corresponds to current CharacterStandard
        public let text: String

        /// Candidate text for UserLexicon.
        ///
        /// Always be traditional characters.
        public let lexiconText: String

        /// Jyutping
        public let romanization: String

        /// User input
        public let input: String

        /// Formatted user input for pre-edit display
        public let mark: String

        /// Rank. Smaller is preferred.
        let order: Int

        public let notation: Notation?

        /// Primary Initializer
        /// - Parameters:
        ///   - type: Candidate type.
        ///   - text: Candidate text for display.
        ///   - lexiconText: Candidate text for UserLexicon.
        ///   - romanization: Jyutping.
        ///   - input: User input for this Candidate.
        ///   - mark: Formatted user input for pre-edit display.
        ///   - notation: Notation
        public init(type: CandidateType = .cantonese, text: String, lexiconText: String? = nil, romanization: String, input: String, mark: String? = nil, notation: Notation? = nil) {
                self.type = type
                self.text = text
                self.lexiconText = lexiconText ?? text
                self.romanization = romanization
                self.input = input
                self.mark = mark ?? input
                self.order = 0
                self.notation = notation
        }

        /// CoreIME Internal Initializer
        init(text: String, romanization: String, input: String, mark: String, order: Int, notation: Notation?) {
                self.type = .cantonese
                self.text = text
                self.lexiconText = text
                self.romanization = romanization
                self.input = input
                self.mark = mark
                self.order = order
                self.notation = notation
        }

        /// Create a Candidate with an emoji or a symbol
        /// - Parameters:
        ///   - symbol: Emoji/Symbol text
        ///   - cantonese: Cantonese word for this Emoji/Symbol
        ///   - romanization: Romanization (Jyutping) of Cantonese word
        ///   - input: User input for this Candidate
        ///   - isEmoji: Emoji or symbol
        init(symbol: String, cantonese: String, romanization: String, input: String, isEmoji: Bool) {
                self.type = isEmoji ? .emoji : .symbol
                self.text = symbol
                self.lexiconText = cantonese
                self.romanization = romanization
                self.input = input
                self.mark = input
                self.order = 0
                self.notation = nil
        }

        /// Create a Candidate for keyboard compose
        /// - Parameters:
        ///   - text: Symbol text for this key compose
        ///   - comment: Name comment of this key symbol
        ///   - secondaryComment: Unicode code point
        ///   - input: User input for this Candidate
        public init(text: String, comment: String?, secondaryComment: String?, input: String) {
                self.type = .compose
                self.text = text
                self.lexiconText = comment ?? ""
                self.romanization = secondaryComment ?? ""
                self.input = input
                self.mark = input
                self.order = 0
                self.notation = nil
        }

        /// type == .cantonese
        public var isCantonese: Bool {
                return self.type == .cantonese
        }

        // Equatable
        public static func ==(lhs: Candidate, rhs: Candidate) -> Bool {
                if lhs.isCantonese && rhs.isCantonese {
                        return lhs.text == rhs.text && lhs.romanization == rhs.romanization
                } else {
                        return lhs.text == rhs.text
                }
        }

        // Hashable
        public func hash(into hasher: inout Hasher) {
                switch type {
                case .cantonese:
                        hasher.combine(text)
                        hasher.combine(romanization)
                case .text:
                        hasher.combine(text)
                case .emoji:
                        hasher.combine(text)
                case .emojiSequence:
                        hasher.combine(text)
                case .symbol:
                        hasher.combine(text)
                case .symbolSequence:
                        hasher.combine(text)
                case .compose:
                        hasher.combine(text)
                }
        }

        public static func +(lhs: Candidate, rhs: Candidate) -> Candidate {
                let newText: String = lhs.text + rhs.text
                let newLexiconText: String = lhs.lexiconText + rhs.lexiconText
                let newRomanization: String = lhs.romanization + " " + rhs.romanization
                let newInput: String = lhs.input + rhs.input
                let newMark: String = lhs.mark + " " + rhs.mark
                return Candidate(text: newText, lexiconText: newLexiconText, romanization: newRomanization, input: newInput, mark: newMark)
        }
}

extension Array where Element == Candidate {

        /// Returns a new Candidate by concatenating this Candidate sequence.
        /// - Returns: Single, concatenated Candidate.
        public func joined() -> Candidate {
                let text: String = map(\.text).joined()
                let lexiconText: String = map(\.lexiconText).joined()
                let romanization: String = map(\.romanization).joined(separator: " ")
                let input: String = map(\.input).joined()
                return Candidate(text: text, lexiconText: lexiconText, romanization: romanization, input: input)
        }
}

extension Candidate {
        public static let example: Candidate = Candidate(text: "舉例", lexiconText: "舉例", romanization: "geoi2 lai6", input: "geoilai", notation: .example)
}
