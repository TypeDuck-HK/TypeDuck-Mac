import SwiftUI
import CoreIME

struct CandidateContentLabel: View {

        let candidate: DisplayCandidate

        var body: some View {
                HStack(spacing: 18) {
                        CantoneseLabel(text: candidate.candidate.text, romanization: candidate.candidate.romanization, shouldDisplayRomanization: candidate.candidate.isCantonese)
                        VStack(alignment: .leading, spacing: 0) {
                                ForEach(0..<candidate.comments.count, id: \.self) { index in
                                        let comment = candidate.comments[index]
                                        if comment.language == .English {
                                                Text(verbatim: comment.text).font(.englishComment)
                                        } else if comment.language == .Indonesian {
                                                Text(verbatim: comment.text).font(.indonesianComment)
                                        }
                                }
                        }
                        VStack(alignment: .leading, spacing: 0) {
                                ForEach(0..<candidate.comments.count, id: \.self) { index in
                                        let comment = candidate.comments[index]
                                        if comment.language.isDevanagari {
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
