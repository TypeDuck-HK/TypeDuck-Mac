import SwiftUI
import CoreIME

struct CandidateLabel: View {

        let candidate: DisplayCandidate
        let index: Int
        let shouldHighlight: Bool

        @State private var isPopoverPresented: Bool = false

        var body: some View {
                let shouldDisplayNotationButton: Bool = shouldDisplayNotationButton
                HStack {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                                SerialNumberLabel(index: index).opacity(shouldHighlight ? 1 : 0.75)
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
                .padding(.vertical, candidate.candidate.isCantonese ? 0 : 8)
                .foregroundStyle(shouldHighlight ? Color.white : Color.primary)
                .background(shouldHighlight ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                .contentShape(Rectangle())
                .popover(isPresented: $isPopoverPresented, attachmentAnchor: .point(.trailing), arrowEdge: .trailing) {
                        if let notation = candidate.candidate.notation {
                                NotationView(notation: notation, comments: candidate.comments).padding()
                        }
                }
        }

        private var shouldDisplayNotationButton: Bool {
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
        }
}

#Preview {
        CandidateLabel(candidate: DisplayCandidate(candidate: .example, candidateIndex: 3), index: 3, shouldHighlight: false)
}
