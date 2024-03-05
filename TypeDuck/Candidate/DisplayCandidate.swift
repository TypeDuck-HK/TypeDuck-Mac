import Foundation
import CoreIME

struct DisplayCandidate: Hashable {

        let candidate: Candidate
        let candidateIndex: Int
        let comments: [Comment]

        init(candidate: Candidate, candidateIndex: Int) {
                self.candidate = candidate
                self.candidateIndex = candidateIndex
                self.comments = {
                        switch candidate.type {
                        case .cantonese:
                                return Self.generateComments(from: candidate.notation)
                        case .text:
                                return []
                        case .emoji, .symbol, .emojiSequence, .symbolSequence:
                                var comments: [Comment] = []
                                let cantoneseText = candidate.lexiconText
                                if !(cantoneseText.isEmpty) {
                                        let cantoneseComment = Comment(language: .Cantonese, text: "〔\(cantoneseText)〕")
                                        comments.append(cantoneseComment)
                                }
                                return comments
                        case .compose:
                                var comments: [Comment] = []
                                let cantoneseText = candidate.lexiconText
                                if !(cantoneseText.isEmpty) {
                                        let cantoneseComment = Comment(language: .Cantonese, text: "〔\(cantoneseText)〕")
                                        comments.append(cantoneseComment)
                                }
                                let unicodeCodePoint = candidate.romanization
                                if !(unicodeCodePoint.isEmpty) {
                                        let unicodeComment =  Comment(language: .Unicode, text: unicodeCodePoint)
                                        comments.append(unicodeComment)
                                }
                                return comments
                        }
                }()
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
                        case .Unicode:
                                return nil
                        }
                }
                return comments.compactMap({ $0 })
        }
}
