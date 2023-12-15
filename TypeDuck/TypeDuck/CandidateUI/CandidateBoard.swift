import SwiftUI

struct CandidateBoard: View {

        @EnvironmentObject private var context: AppContext

        var body: some View {
                let highlightedIndex = context.highlightedIndex
                VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<context.displayCandidates.count, id: \.self) { index in
                                CandidateLabel(candidate: context.displayCandidates[index], index: index, shouldHighlight: index == highlightedIndex)
                        }
                }
                .padding(4)
                .roundedHUDVisualEffect()
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
