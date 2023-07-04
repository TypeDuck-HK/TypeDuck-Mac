import Foundation
import CoreIME

struct DisplayCandidate: Hashable {

        let candidate: Candidate
        let candidateIndex: Int
        let comments: [Comment]

        init(candidate: Candidate, candidateIndex: Int) {
                self.candidate = candidate
                self.candidateIndex = candidateIndex
                switch candidate.type {
                case .cantonese:
                        self.comments = Self.generateComments(from: candidate.notation)
                default:
                        self.comments = []
                }
        }

        private static func generateComments(from notation: Notation?) -> [Comment] {
                guard let notation else { return [] }
                let comments = AppSettings.enabledCommentLanguages.map { language -> Comment? in
                        switch language {
                        case .Cantonese:
                                return nil
                        case .English:
                                guard notation.english.isValid else { return nil }
                                return Comment(language: language, text: notation.english)
                        case .Hindi:
                                guard notation.hindi.isValid else { return nil }
                                return Comment(language: language, text: notation.hindi)
                        case .Indonesian:
                                guard notation.indonesian.isValid else { return nil }
                                return Comment(language: language, text: notation.indonesian)
                        case .Nepali:
                                guard notation.nepali.isValid else { return nil }
                                return Comment(language: language, text: notation.nepali)
                        case .Urdu:
                                guard notation.urdu.isValid else { return nil }
                                return Comment(language: language, text: notation.urdu)
                        }
                }
                return comments.compactMap({ $0 })
        }
}
