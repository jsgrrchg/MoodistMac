import SwiftUI

extension View {
    @ViewBuilder
    func applyAppAccent(_ color: Color?) -> some View {
        if let color {
            self.accentColor(color).tint(color)
        } else {
            self
        }
    }
}
