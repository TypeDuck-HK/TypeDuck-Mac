import Foundation
import InputMethodKit

extension IMKTextInput {

        /// (x: origin.x, y: origin.y: width 1, height: maxY)
        var cursorBlock: CGRect {
                var lineHeightRectangle: CGRect = .init()
                self.attributes(forCharacterIndex: 0, lineHeightRectangle: &lineHeightRectangle)
                return lineHeightRectangle
        }

        func insert(_ text: String) {
                let convertedText: NSString = text as NSString
                self.insertText(convertedText, replacementRange: NSRange.replacementRange)
        }

        func mark(_ text: String) {
                let convertedText: NSString = text as NSString
                self.setMarkedText(convertedText, selectionRange: NSRange(location: convertedText.length, length: 0), replacementRange: NSRange.replacementRange)
        }

        func clearMarkedText() {
                self.setMarkedText(NSString(), selectionRange: NSRange(location: 0, length: 0), replacementRange: NSRange.replacementRange)
        }
}

private extension NSRange {
        static let replacementRange = NSRange(location: NSNotFound, length: 0)
}
