import AppKit

enum MoodistAppActions {
    static func showCustomizedAboutPanel() {
        let credits = NSMutableAttributedString(string: "\(L10n.createdBy): José Gurruchaga\n")
        let buyMeACoffeeText = NSAttributedString(
            string: L10n.buyMeACoffee,
            attributes: [.link: "https://buymeacoffee.com/jsgrrchg"]
        )
        credits.append(buyMeACoffeeText)

        NSApplication.shared.orderFrontStandardAboutPanel(options: [.credits: credits])
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    static func openBuyMeACoffee() {
        guard let url = URL(string: "https://buymeacoffee.com/jsgrrchg") else { return }
        NSWorkspace.shared.open(url)
    }
}
