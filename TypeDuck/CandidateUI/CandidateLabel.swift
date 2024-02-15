import SwiftUI
import CoreIME

struct CandidateLabel: View {

        let candidate: DisplayCandidate
        let index: Int
        let shouldHighlight: Bool

        @State private var isPopoverPresented: Bool = false

        var body: some View {
                HStack {
                        HStack(alignment: .lastTextBaseline, spacing: 14) {
                                SerialNumberLabel(index: index).foregroundColor(shouldHighlight ? .white : .secondary)
                                CandidateContentView(candidate: candidate, shouldDisplayNotation: shouldDisplayNotation)
                        }
                        Spacer()
                        if shouldDisplayNotation {
                                Image.infoCircle
                                        .font(.title3)
                                        .contentShape(Rectangle())
                                        .onHover { isHovering in
                                                guard isPopoverPresented != isHovering else { return }
                                                isPopoverPresented = isHovering
                                        }
                        }
                }
                .padding(EdgeInsets(top: 4, leading: 8, bottom: candidate.candidate.isCantonese && candidate.comments.contains { $0.language == .Urdu } ? 0.5 : 4, trailing: 8))
                .foregroundColor(shouldHighlight ? .white : .primary)
                .background(shouldHighlight ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .contentShape(Rectangle())
                .popover(isPresented: $isPopoverPresented, attachmentAnchor: .point(.trailing), arrowEdge: .trailing) {
                        if shouldDisplayNotation {
                                NotationView(notation: candidate.candidate.notation!, comments: candidate.comments).padding()
                        }
                }
        }

        private var shouldDisplayNotation: Bool {
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
