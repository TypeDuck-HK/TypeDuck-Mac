import SwiftUI

/// Display Cantonese text and Jyutping romanization
struct CantoneseLabel: View {

        /// Cantonese text
        let text: String

        /// Jyutping
        let romanization: String

        let shouldDisplayRomanization: Bool

        var body: some View {
                VStack(alignment: .leading, spacing: 0) {
                        if shouldDisplayRomanization {
                                Text(verbatim: romanization).font(.romanization)
                        }
                        Text(verbatim: text).font(.candidate).tracking(16)
                }
        }
}

#Preview {
        CantoneseLabel(text: "示例", romanization: "si6 lai6", shouldDisplayRomanization: true)
}
