import SwiftUI

extension Font {

        static let serialNumber: Font = Font.body.monospacedDigit()

        /// For Cantonese text
        static let candidate: Font = Font.title2

        /// For Jyutping romanization text
        static let romanization: Font = Font.callout

        static let englishComment: Font = Font.title3
        static let indonesianComment: Font = Font.custom("Times New Roman", size: 14, relativeTo: .title3)
        static let devanagariComment: Font = Font.custom("Devanagari MT", size: 14, relativeTo: .title3)
        static let urduComment: Font = Font.custom("Noto Nastaliq Urdu", size: 14, relativeTo: .title3)
}
