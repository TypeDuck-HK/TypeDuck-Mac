import SwiftUI
import CoreIME

struct CandidateBoard: View {

        @EnvironmentObject private var context: AppContext

        var body: some View {
                let highlightedIndex = context.highlightedIndex
                VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<context.displayCandidates.count, id: \.self) { index in
                                let shouldHighlight: Bool = index == highlightedIndex
                                let candidate: DisplayCandidate = context.displayCandidates[index]
                                let subCandidates = candidate.candidate.subNotations.map({ notation -> DisplayCandidate in
                                        let convertedCandidate = Candidate(text: notation.word, romanization: notation.jyutping, input: String.empty, notation: notation)
                                        return DisplayCandidate(candidate: convertedCandidate, candidateIndex: -1)
                                })
                                VStack(alignment: .leading, spacing: 0) {
                                        CandidateLabel(index: index, candidate: candidate, shouldHighlight: shouldHighlight)
                                                .background(shouldHighlight ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                                        SubCandidatesView(subCandidates: subCandidates, shouldHighlight: shouldHighlight)
                                }
                                .foregroundStyle(shouldHighlight ? Color.white : Color.primary)
                                .background(shouldHighlight ? Color.accentColor.opacity(0.95) : Color.clear, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                }
                .padding(4)
                .roundedHUDVisualEffect()
                .padding(10)
                .fixedSize()
        }
}

#Preview {
        let context = AppContext()
        context.update(with: [.init(candidate: .example, candidateIndex: 0),
                              .init(candidate: .example, candidateIndex: 1),
                              .init(candidate: .example, candidateIndex: 2)],
                       highlight: .start)
        return CandidateBoard().environmentObject(context)
}

private struct SubCandidatesView: View {
        let subCandidates: [DisplayCandidate]
        let shouldHighlight: Bool
        var body: some View {
                ForEach(0..<subCandidates.count, id: \.self) { index in
                        CandidateLabel(index: -1, candidate: subCandidates[index], shouldHighlight: shouldHighlight)
                }
        }
}
