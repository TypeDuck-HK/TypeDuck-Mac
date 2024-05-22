import SwiftUI
import CoreIME

struct CandidateContentView: View {

        let candidate: DisplayCandidate
        let hasNotationDisplayButton: Bool

        var body: some View {
                let annotationComments = candidate.comments.filter(\.language.isAnnotation)
                let latinComments = candidate.comments.filter(\.language.isLatin)
                let devanagariComments = candidate.comments.filter(\.language.isDevanagari)
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                        CantoneseLabel(text: candidate.candidate.text, romanization: candidate.candidate.romanization, shouldDisplayRomanization: candidate.candidate.isCantonese)
                        if !hasNotationDisplayButton, let labelText = candidate.candidate.notation?.label, labelText.isValid {
                                let labelList = Decorator.labelList(of: labelText)
                                if !(labelList.isEmpty) {
                                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                                                ForEach(0..<labelList.count, id: \.self) { index in
                                                        let label = labelList[index]
                                                        Text(verbatim: label).foregroundStyle(Color.secondary)
                                                }
                                        }
                                }
                        }
                        if !(annotationComments.isEmpty) {
                                ForEach(0..<annotationComments.count, id: \.self) { index in
                                        let comment = annotationComments[index]
                                        Text(verbatim: comment.text).font(comment.language.font)
                                }
                        }
                        if !(latinComments.isEmpty) {
                                VStack(alignment: .leading, spacing: 2) {
                                        ForEach(0..<latinComments.count, id: \.self) { index in
                                                let comment = latinComments[index]
                                                Text(verbatim: comment.text).font(comment.language.font)
                                        }
                                }
                        }
                        if !(devanagariComments.isEmpty) {
                                VStack(alignment: .leading, spacing: -6) {
                                        ForEach(0..<devanagariComments.count, id: \.self) { index in
                                                let comment = devanagariComments[index]
                                                Text(verbatim: comment.text).font(comment.language.font)
                                        }
                                }
                        }
                        if let comment = candidate.comments.first(where: \.language.isRTL) {
                                Text(verbatim: comment.text).font(comment.language.font)
                        }
                }
        }
}

#Preview {
        CandidateContentView(candidate: DisplayCandidate(candidate: .example, candidateIndex: 3), hasNotationDisplayButton: true)
}
