import SwiftUI
import CoreIME

struct NotationView: View {

        let notation: Notation

        var body: some View {
                VStack(alignment: .leading, spacing: 8) {
                        if notation.isSandhi {
                                Text(verbatim: "Changed Tone")
                        }
                        if notation.partOfSpeech.isValid {
                                Text(verbatim: "Part of Speech: \(notation.partOfSpeech)")
                        }
                        if notation.register.isValid {
                                Text(verbatim: "Register: \(notation.register)")
                        }
                        if notation.label.isValid {
                                Text(verbatim: "Label: \(notation.label)")
                        }
                        if notation.written.isValid {
                                Text(verbatim: "Written: \(notation.written)")
                        }
                        if notation.colloquial.isValid {
                                Text(verbatim: "Colloquial: \(notation.colloquial)")
                        }
                }
        }
}
