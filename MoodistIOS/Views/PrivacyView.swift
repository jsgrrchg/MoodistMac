import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            Text(T("privacy_body", "Moodist does not collect listening history or personal data. Your mixes and preferences are stored on this device and may be included in your device backups. Preference files are shared only when you export them. Notifications are optional and used for timers. You can delete your local data in Settings. External websites and apps you share with have their own privacy policies."))
                .frame(maxWidth: .infinity, alignment: .leading).padding()
        }.navigationTitle(T("privacy", "Privacy"))
    }
}
