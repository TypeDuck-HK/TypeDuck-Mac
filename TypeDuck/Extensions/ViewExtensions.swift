import SwiftUI

extension View {
        func block() -> some View {
                return self.padding().background(Color.textBackgroundColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
}
