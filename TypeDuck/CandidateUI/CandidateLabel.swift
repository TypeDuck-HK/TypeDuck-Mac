import SwiftUI
import CoreIME

struct CandidateLabel: View {

        init(index: Int, candidate: DisplayCandidate, shouldHighlight: Bool) {
                self.labelOpacity = (index == -1) ? 0 : (shouldHighlight ? 1: 0.75)
                self.index = index
                self.candidate = candidate
                self.shouldHighlight = shouldHighlight
                self.isCantoneseCandidate = candidate.candidate.isCantonese
                self.isCompoundCandidate = candidate.candidate.isCompound
                self.shouldDisplayNotationButton = {
                        guard !(candidate.candidate.isCompound) else { return true }
                        guard let notation = candidate.candidate.notation else { return false }
                        if notation.partOfSpeech.isValid {
                                return true
                        } else if notation.register.isValid {
                                return true
                        } else if notation.normalized.isValid {
                                return true
                        } else if notation.written.isValid {
                                return true
                        } else if notation.vernacular.isValid {
                                return true
                        } else if notation.collocation.isValid {
                                return true
                        } else if candidate.comments.contains(where: \.language.isTranslation) {
                                return true
                        } else {
                                return false
                        }
                }()
        }

        private let labelOpacity: Double
        private let index: Int
        private let candidate: DisplayCandidate
        private let shouldHighlight: Bool
        private let isCantoneseCandidate: Bool
        private let isCompoundCandidate: Bool
        private let shouldDisplayNotationButton: Bool

        @State private var isPopoverPresented: Bool = false

        var body: some View {
                HStack {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                                SerialNumberLabel(index: index).opacity(labelOpacity)
                                CandidateContentView(candidate: candidate, hasNotationDisplayButton: shouldDisplayNotationButton)
                        }
                        Spacer()
                        if shouldDisplayNotationButton {
                                Image.infoCircle
                                        .font(.title3)
                                        .contentShape(Rectangle())
                                        .onHover { isHovering in
                                                guard isPopoverPresented != isHovering else { return }
                                                isPopoverPresented = isHovering
                                        }
                        }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, isCantoneseCandidate ? 0 : 8)
                .contentShape(Rectangle())
                .popover(isPresented: $isPopoverPresented, attachmentAnchor: .point(.trailing), arrowEdge: .trailing) {
                        let notations: [Notation] = {
                                guard !isCompoundCandidate else { return candidate.candidate.subNotations }
                                guard let notation = candidate.candidate.notation else { return [] }
                                return [notation]
                        }()
                        let commentsList: [[Comment]] = isCompoundCandidate ? notations.map(\.comments) : [candidate.comments]
                        VStack(alignment: .leading) {
                                ForEach(0..<notations.count, id: \.self) { index in
                                        if index != 0 {
                                                Divider()
                                        }
                                        let notation = notations[index]
                                        let comments = commentsList[index]
                                        NotationView(notation: notation, comments: comments)
                                }
                        }
                        .foregroundStyle(Color.primary)
                        .fixedSize()
                        .padding(12)
                }
        }
}

#Preview {
        CandidateLabel(index: 3, candidate: DisplayCandidate(candidate: .example, candidateIndex: 3), shouldHighlight: false)
}
