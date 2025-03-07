public enum CandidateType: Int, Sendable {

        case cantonese

        /// Plain text. Examples: iPad, macOS
        case text

        /// Note that `Candidate.text.count == 1` not always true
        case emoji

        /// Note that `Candidate.text.count == 1` not always true
        case symbol

        /// macOS Keyboard composed text. Mainly for PunctuationKey.
        case compose
}

public struct Candidate: Hashable, Comparable, Sendable {

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

        /// Lexicon detail information
        public let notation: Notation?

        /// For Compound Translations
        public let subNotations: [Notation]

        /// Primary Initializer
        /// - Parameters:
        ///   - type: Candidate type.
        ///   - text: Candidate text for display.
        ///   - lexiconText: Candidate text for UserLexicon.
        ///   - romanization: Jyutping.
        ///   - input: User input for this Candidate.
        ///   - mark: Formatted user input for pre-edit display.
        ///   - order: Rank. Smaller is preferred.
        ///   - notation: Lexicon detail information.
        ///   - subNotations: For Compound Translations.
        public init(type: CandidateType = .cantonese, text: String, lexiconText: String? = nil, romanization: String, input: String, mark: String? = nil, order: Int = 0, notation: Notation? = nil, subNotations: [Notation] = []) {
                self.type = type
                self.text = text
                self.lexiconText = lexiconText ?? text
                self.romanization = romanization
                self.input = input
                self.mark = mark ?? input
                self.order = order
                self.notation = notation
                self.subNotations = subNotations
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
                self.subNotations = []
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
                self.subNotations = []
        }

        /// type == .cantonese
        public var isCantonese: Bool {
                return self.type == .cantonese
        }

        /// type != .cantonese
        public var isNotCantonese: Bool {
                return self.type != .cantonese
        }

        /// Concatenated by multiple lexicons
        public var isCompound: Bool {
                return subNotations.isNotEmpty
        }

        public var isUserLexicon: Bool {
                return order < 0
        }

        // Equatable
        public static func ==(lhs: Candidate, rhs: Candidate) -> Bool {
                guard lhs.type == rhs.type else { return false }
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
                case .symbol:
                        hasher.combine(text)
                case .compose:
                        hasher.combine(text)
                }
        }

        // Comparable
        public static func < (lhs: Candidate, rhs: Candidate) -> Bool {
                guard lhs.input.count == rhs.input.count else { return lhs.input.count > rhs.input.count }
                guard lhs.text.count == rhs.text.count else { return lhs.text.count < rhs.text.count }
                return lhs.order < rhs.order
        }

        public static func +(lhs: Candidate, rhs: Candidate) -> Candidate? {
                guard lhs.isCantonese && rhs.isCantonese else { return nil }
                let newText: String = lhs.text + rhs.text
                let newLexiconText: String = lhs.lexiconText + rhs.lexiconText
                let newRomanization: String = lhs.romanization + " " + rhs.romanization
                let newInput: String = lhs.input + rhs.input
                let newMark: String = lhs.mark + " " + rhs.mark
                let step: Int = 1_000_000
                let newOrder: Int = (lhs.order + step) + (rhs.order + step)
                let newSubNotations: [Notation] = {
                        var items: [Notation] = []
                        if let lhsNotation = lhs.notation {
                                items.append(lhsNotation)
                        } else {
                                items.append(contentsOf: lhs.subNotations)
                        }
                        if let rhsNotation = rhs.notation {
                                items.append(rhsNotation)
                        } else {
                                items.append(contentsOf: rhs.subNotations)
                        }
                        return items.uniqued()
                }()
                return Candidate(text: newText, lexiconText: newLexiconText, romanization: newRomanization, input: newInput, mark: newMark, order: newOrder, subNotations: newSubNotations)
        }
}

extension Array where Element == Candidate {

        /// Returns a new Candidate by concatenating this Candidate sequence.
        /// - Returns: Single, concatenated Candidate.
        public func joined() -> Candidate? {
                let isAllCantonese: Bool = !(contains(where: \.isNotCantonese))
                guard isAllCantonese else { return nil }
                let text: String = map(\.text).joined()
                let lexiconText: String = map(\.lexiconText).joined()
                let romanization: String = map(\.romanization).joined(separator: " ")
                let input: String = map(\.input).joined()
                let mark: String = map(\.mark).joined(separator: " ")
                let step: Int = 1_000_000
                let order: Int = map(\.order).reduce(0, { $0 + $1 + step })
                let subNotations: [Notation] = compactMap(\.notation)
                return Candidate(text: text, lexiconText: lexiconText, romanization: romanization, input: input, mark: mark, order: order, subNotations: subNotations)
        }
}

extension Array where Element == Candidate {
        public func transformed(with characterStandard: CharacterStandard) -> [Candidate] {
                let hasUserLexicon: Bool = self.first?.isUserLexicon ?? false
                if hasUserLexicon {
                        return self.compactMap({ item -> Candidate? in
                                if item.isUserLexicon {
                                        return Engine.embedNotations(for: item).transformed(to: characterStandard)
                                } else if item.isCompound {
                                        return nil
                                } else {
                                        return item.transformed(to: characterStandard)
                                }
                        })
                        .uniqued()
                } else {
                        return self.map({ $0.transformed(to: characterStandard) }).uniqued()
                }
        }
}

extension Candidate {
        public static let example: Candidate = Candidate(text: "舉例", lexiconText: "舉例", romanization: "geoi2 lai6", input: "geoilai", notation: .example)
}
