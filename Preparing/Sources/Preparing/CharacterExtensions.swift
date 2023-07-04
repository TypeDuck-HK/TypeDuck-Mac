extension Character {
        /// a-z or A-Z
        var isBasicLatinLetter: Bool {
                return ("a"..."z") ~= self || ("A"..."Z") ~= self
        }
        /// a-z
        var isLowercasedBasicLatinLetter: Bool {
                return ("a"..."z") ~= self
        }
        /// A-Z
        var isUppercasedBasicLatinLetter: Bool {
                return ("A"..."Z") ~= self
        }
}
