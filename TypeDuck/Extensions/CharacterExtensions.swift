extension Character {

        /// U+0020
        static let space: Character = "\u{20}"

        /// U+0020
        var isSpace: Bool {
                return self == Self.space
        }

        /// U+0027 ( ' ) apostrophe
        static let separator: Character = "\u{27}"

        /// U+0027 ( ' ) apostrophe
        var isSeparator: Bool {
                return self == Self.separator
        }

        /// U+0060, backquote, grave accent
        static let backtick: Character = "`"

        /// U+0060, backquote, grave accent
        var isBacktick: Bool {
                return self == Self.backtick
        }

        /// a-z or A-Z
        var isBasicLatinLetter: Bool {
                return ("a"..."z") ~= self || ("A"..."Z") ~= self
        }

        /// A Boolean value indicating whether this character represents a tone number (1-6).
        var isTone: Bool {
                return ("1"..."6") ~= self
        }

        /// A Boolean value indicating whether this character represents a space or a tone number.
        var isSpaceOrTone: Bool {
                return self.isSpace || self.isTone
        }

        /// A Boolean value indicating whether this character represents a separator or a tone number.
        var isSeparatorOrTone: Bool {
                return self.isSeparator || self.isTone
        }

        /// A Boolean value indicating whether this character represents a space, or a separator, or a tone number.
        var isSpaceOrSeparatorOrTone: Bool {
                return self.isSpace || self.isSeparator || self.isTone
        }
}

extension Character {

        private static let reverseLookupTriggers: Set<Character> = ["r", "v", "x", "q"]

        /// r / v / x / q
        var isReverseLookupTrigger: Bool {
                return Character.reverseLookupTriggers.contains(self)
        }
}
