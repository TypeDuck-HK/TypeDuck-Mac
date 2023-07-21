import SwiftUI
import CoreIME

struct CandidateLabel: View {

        let candidate: DisplayCandidate
        let index: Int
        let shouldHighlight: Bool

        @State private var isPopoverPresented: Bool = false

        var body: some View {
                HStack {
                        HStack(spacing: 14) {
                                SerialNumberLabel(index: index).foregroundColor(shouldHighlight ? .white : .secondary)
                                CandidateContentLabel(candidate: candidate)
                        }
                        Spacer()
                        Image.infoCircle
                                .font(.title3)
                                .contentShape(Rectangle())
                                .onHover { isHovering in
                                        guard isPopoverPresented != isHovering else { return }
                                        isPopoverPresented = isHovering
                                }
                                .opacity(shouldDisplayInfoCircle ? 1 : 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, candidate.candidate.isCantonese ? 0.5 : 4)
                .foregroundColor(shouldHighlight ? .white : .primary)
                .background(shouldHighlight ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .contentShape(Rectangle())
                .popover(isPresented: $isPopoverPresented, attachmentAnchor: .point(.trailing), arrowEdge: .trailing) {
                        if let notation = candidate.candidate.notation {
                                NotationView(notation: notation).padding()
                        }
                }
        }

        private var shouldDisplayInfoCircle: Bool {
                guard let notation = candidate.candidate.notation else { return false }
                if notation.partOfSpeech.isValid {
                        return true
                } else if notation.partOfSpeech.isValid {
                        return true
                } else if notation.register.isValid {
                        return true
                } else if notation.isSandhi {
                        return true
                } else if notation.literaryColloquial.isValid {
                        return true
                } else if notation.label.isValid {
                        return true
                } else if notation.normalized.isValid {
                        return true
                } else if notation.written.isValid {
                        return true
                } else if notation.vernacular.isValid {
                        return true
                } else if notation.collocation.isValid {
                        return true
                } else {
                        return false
                }
        }
}
