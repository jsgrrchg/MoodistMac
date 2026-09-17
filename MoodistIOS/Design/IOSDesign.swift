import SwiftUI
import MoodistKit

func T(_ key: String, _ fallback: String) -> String {
    MoodistResources.localizedString("ios_" + key, fallback: fallback)
}

struct PlaybackControlsStyle: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparency = true
    func body(content: Content) -> some View {
        if reduceTransparency || !transparency {
            content.buttonStyle(.bordered).controlSize(.large)
        } else {
            content.buttonStyle(.glass).controlSize(.large)
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

enum IOSAccent {
    static let choices = ["system", "blue", "purple", "pink", "red", "orange", "yellow", "green", "graphite"]
    static func color(_ raw: String) -> Color? {
        switch raw {
        case "system": return nil
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        default: return .gray
        }
    }
    static func label(_ raw: String) -> String {
        switch raw {
        case "system": return L10n.accentColorSystem
        case "blue": return L10n.accentColorBlue
        case "purple": return L10n.accentColorPurple
        case "pink": return L10n.accentColorPink
        case "red": return L10n.accentColorRed
        case "orange": return L10n.accentColorOrange
        case "yellow": return L10n.accentColorYellow
        case "green": return L10n.accentColorGreen
        default: return L10n.accentColorGraphite
        }
    }
}

struct PlayerSurfaceStyle: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparency = true
    func body(content: Content) -> some View {
        if reduceTransparency || !transparency {
            content.background(Color(uiColor: .secondarySystemBackground), in: Capsule())
        } else {
            content.glassEffect(.regular, in: .capsule)
        }
    }
}
