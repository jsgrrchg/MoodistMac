import SwiftUI
import MoodistKit

func T(_ key: String, _ fallback: String) -> String {
    MoodistResources.localizedString("ios_" + key, fallback: fallback)
}

struct GlassControlSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparency = true
    func body(content: Content) -> some View {
        if reduceTransparency || !transparency {
            content.padding().background(.background, in: .rect(cornerRadius: 24))
        } else {
            content.padding().glassEffect(.regular, in: .rect(cornerRadius: 24))
        }
    }
}

struct SoundSymbol: View {
    let name: String
    var body: some View {
        if name == "palm-tree-solid" {
            Image("PalmTreeSolid", bundle: MoodistResources.bundle).resizable().scaledToFit()
        } else {
            Image(systemName: UIImage(systemName: name) == nil ? "waveform" : name)
        }
    }
}
