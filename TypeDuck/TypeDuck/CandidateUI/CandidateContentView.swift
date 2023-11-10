import SwiftUI
import CoreIME

struct CandidateContentView: View {

        let candidate: DisplayCandidate

        var body: some View {
                let annotationComments = candidate.comments.filter({ $0.language.isAnnotation })
                let latinComments = candidate.comments.filter({ $0.language.isLatin })
                let devanagariComments = candidate.comments.filter({ $0.language.isDevanagari })
                HStack(spacing: 18) {
                        CantoneseLabel(text: candidate.candidate.text, romanization: candidate.candidate.romanization, shouldDisplayRomanization: candidate.candidate.isCantonese)
                        if !(annotationComments.isEmpty) {
                                HStack {
                                        ForEach(0..<annotationComments.count, id: \.self) { index in
                                                let comment = annotationComments[index]
                                                Text(verbatim: comment.text)
                                        }
                                }
                        }
                        if !(latinComments.isEmpty) {
                                VStack(alignment: .leading, spacing: 0) {
                                        ForEach(0..<latinComments.count, id: \.self) { index in
                                                let comment = latinComments[index]
                                                Text(verbatim: comment.text).font((comment.language == .Indonesian) ? .indonesianComment : .englishComment)
                                        }
                                }
                        }
                        if !(devanagariComments.isEmpty) {
                                VStack(alignment: .leading, spacing: 0) {
                                        ForEach(0..<devanagariComments.count, id: \.self) { index in
                                                let comment = devanagariComments[index]
                                                Text(verbatim: comment.text).font(.devanagariComment)
                                        }
                                }
                        }
                        if let comment = candidate.comments.first(where: { $0.language.isRTL }) {
                                Text(verbatim: comment.text).font(.urduComment)
                        }
                }
        }
}
