extension Candidate {

        /// Convert Cantonese Candidate text to the specific variant
        /// - Parameter variant: Character variant
        /// - Returns: Transformed Candidate
        public func transformed(to variant: CharacterStandard) -> Candidate {
                guard self.isCantonese else { return self }
                switch variant {
                case .traditional:
                        return self
                case .simplified:
                        let convertedText: String = Converter.convert(text, to: variant)
                        return Candidate(text: convertedText, lexiconText: lexiconText, romanization: romanization, input: input, mark: mark, notation: notation)
                }
        }
}

/// Character Variant Converter
public struct Converter {

        /// Convert original (traditional) text to the specific variant
        /// - Parameters:
        ///   - text: Original (traditional) text
        ///   - variant: Character Variant
        /// - Returns: Converted text
        public static func convert(_ text: String, to variant: CharacterStandard) -> String {
                switch variant {
                case .traditional:
                        return text
                case .simplified:
                        return Simplifier.convert(text)
                }
        }

}
