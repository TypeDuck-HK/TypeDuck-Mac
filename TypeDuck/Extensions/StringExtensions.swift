import Foundation

extension String {

        var shortcut: Int {
                let anchors = self.split(separator: Character.space).compactMap(\.first)
                return String(anchors).hash
        }

        var ping: Int {
                return self.removedSpacesTones().hash
        }

        /// A subsequence that only contains tones (1-6)
        var tones: String {
                return self.filter(\.isTone)
        }

        /// Remove all tones (1-6)
        /// - Returns: A subsequence that leaves off the tones.
        func removedTones() -> String {
                return self.filter({ !$0.isTone })
        }

        /// Remove all spaces and tones
        /// - Returns: A subsequence that leaves off the spaces and tones.
        func removedSpacesTones() -> String {
                return self.filter({ !$0.isSpaceOrTone })
        }

        /// Remove all spaces, separators and tones
        /// - Returns: A subsequence that leaves off the spaces, separators and tones.
        func removedSpacesSeparatorsTones() -> String {
                return self.filter({ !$0.isSpaceOrSeparatorOrTone })
        }

        static let empty: String = ""

        /// U+0020
        static let space: String = "\u{20}"

        /// U+200B
        static let zeroWidthSpace: String = "\u{200B}"

        /// U+3000. Ideographic Space. 全寬空格
        static let fullWidthSpace: String = "\u{3000}"
}


extension String {

        /// Transform to Full Width characters
        /// - Returns: Full Width characters
        func fullWidth() -> String {
                return self.applyingTransform(.fullwidthToHalfwidth, reverse: true) ?? self
        }
}

