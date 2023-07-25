import Foundation

extension String {

        var shortcut: Int64 {
                let syllables = self.split(separator: Character.space)
                let anchors = syllables.map({ $0.first }).compactMap({ $0 })
                let text: String = String(anchors)
                return Int64(text.hash)
        }

        var ping: Int64 {
                return Int64(self.removedSpacesTones().hash)
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
}


extension String {

        /// Transform to Full Width characters
        /// - Returns: Full Width characters
        func fullWidth() -> String {
                return self.applyingTransform(.fullwidthToHalfwidth, reverse: true) ?? self
        }
}

