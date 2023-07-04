extension Character {

        private static let tones: Set<Character> = ["1", "2", "3", "4", "5", "6"]
        private static let spaceTones: Set<Character> = [" ", "1", "2", "3", "4", "5", "6"]

        /// A Boolean value indicating whether this character represents a tone number (1-6).
        var isTone: Bool {
                return Character.tones.contains(self)
        }

        /// A Boolean value indicating whether this character represents a space or a tone number.
        var isSpaceOrTone: Bool {
                return Character.spaceTones.contains(self)
        }

        /// A Boolean value indicating whether this character represents a separator ( ' ).
        var isSeparator: Bool {
                return self == "'"
        }

        /// a-z or A-Z
        var isBasicLatinLetter: Bool {
                return ("a"..."z") ~= self || ("A"..."Z") ~= self
        }

        /// A Boolean value indicating whether this character represents a separator or a tone number.
        var isSeparatorOrTone: Bool {
                return self.isSeparator || self.isTone
        }
}

extension Character {

        private static let reverseLookupTriggers: Set<Character> = ["r", "v", "x", "q"]

        /// r / v / x / q
        var isReverseLookupTrigger: Bool {
                return Character.reverseLookupTriggers.contains(self)
        }
}
