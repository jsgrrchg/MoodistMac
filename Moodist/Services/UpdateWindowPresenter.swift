//
//  UpdateWindowPresenter.swift
//  MoodistMac
//
//  Presenta la ventana custom de actualización para Sparkle.
//

import AppKit
@preconcurrency import Sparkle
import SwiftUI

enum ReleaseNotesContent: Equatable {
    case html(String, baseURL: URL?)
    case text(String)
}

struct UpdateWindowModel: Equatable {
    enum Phase: Equatable {
        case checking
        case available
        case downloading
        case extracting
        case readyToInstall
        case installing
    }

    var phase: Phase
    var title: String
    var subtitle: String
    var currentVersion: String?
    var newVersion: String?
    var fileSize: String?
    var isCritical: Bool
    var isInformationOnly: Bool
    var infoURL: URL?
    var releaseNotes: ReleaseNotesContent?
    var releaseNotesError: String?
    var progressFraction: Double?
    var progressText: String?
    var primaryActionTitle: String?
    var showsCancel: Bool

    static let placeholder = UpdateWindowModel(
        phase: .checking,
        title: L10n.updateCheckingTitle,
        subtitle: "",
        currentVersion: nil,
        newVersion: nil,
        fileSize: nil,
        isCritical: false,
        isInformationOnly: false,
        infoURL: nil,
        releaseNotes: nil,
        releaseNotesError: nil,
        progressFraction: nil,
        progressText: nil,
        primaryActionTitle: nil,
        showsCancel: true
    )
}

@MainActor
final class UpdateWindowPresenter: NSObject, ObservableObject, NSWindowDelegate {
    @Published var model: UpdateWindowModel = .placeholder
    @Published var isVisible = false

    private var window: NSPanel?
    private var replyHandler: ((SPUUserUpdateChoice) -> Void)?
    private var cancellationHandler: (() -> Void)?
    private var expectedContentLength: UInt64 = 0
    private var receivedContentLength: UInt64 = 0
    private var lastAppcastItem: SUAppcastItem?
    private var lastUserState: SPUUserUpdateState?
    private let defaultWindowSize = CGSize(width: 560, height: 520)

    func showPreview() {
        replyHandler = nil
        cancellationHandler = nil
        expectedContentLength = 122_000_000
        receivedContentLength = 0
        model = UpdateWindowModel(
            phase: .available,
            title: L10n.updateAvailableTitle,
            subtitle: L10n.updateAvailableSubtitle("1.0 Beta 4 (4)", "1.0 Beta 3 (3)"),
            currentVersion: "1.0 Beta 3 (3)",
            newVersion: "1.0 Beta 4 (4)",
            fileSize: formattedFileSize(expectedContentLength),
            isCritical: false,
            isInformationOnly: false,
            infoURL: nil,
            releaseNotes: .text("""
• Floating player controls improved
• New timer presets and cleaner menu
• Better sidebar performance
• Several bug fixes and polish
"""),
            releaseNotesError: nil,
            progressFraction: nil,
            progressText: nil,
            primaryActionTitle: L10n.updateDownload,
            showsCancel: false
        )
        presentWindow()
    }

    func showChecking(cancellation: @escaping () -> Void) {
        replyHandler = nil
        cancellationHandler = cancellation
        expectedContentLength = 0
        receivedContentLength = 0
        model = UpdateWindowModel(
            phase: .checking,
            title: L10n.updateCheckingTitle,
            subtitle: "",
            currentVersion: nil,
            newVersion: nil,
            fileSize: nil,
            isCritical: false,
            isInformationOnly: false,
            infoURL: nil,
            releaseNotes: nil,
            releaseNotesError: nil,
            progressFraction: nil,
            progressText: nil,
            primaryActionTitle: nil,
            showsCancel: true
        )
        presentWindow()
    }

    func showUpdateFound(appcastItem: SUAppcastItem, state: SPUUserUpdateState, reply: @escaping (SPUUserUpdateChoice) -> Void) {
        lastAppcastItem = appcastItem
        lastUserState = state
        replyHandler = reply
        cancellationHandler = nil
        expectedContentLength = appcastItem.contentLength
        receivedContentLength = 0
        let phase: UpdateWindowModel.Phase
        switch state.stage {
        case .downloaded:
            phase = .readyToInstall
        case .installing:
            phase = .installing
        default:
            phase = .available
        }
        model = makeModel(for: phase, appcastItem: appcastItem, state: state)
        presentWindow()
    }

    func updateReleaseNotes(with downloadData: SPUDownloadData) {
        let content = parseReleaseNotes(downloadData)
        var next = model
        next.releaseNotes = content
        next.releaseNotesError = nil
        model = next
    }

    func updateReleaseNotesFailed(_ _: Error) {
        var next = model
        next.releaseNotesError = L10n.updateNotesFailed
        model = next
    }

    func showDownloading(cancellation: @escaping () -> Void) {
        cancellationHandler = cancellation
        updatePhase(.downloading, showsCancel: true, resetProgress: false)
    }

    func updateExpectedContentLength(_ length: UInt64) {
        expectedContentLength = length
        updateDownloadProgress()
    }

    func updateReceivedData(_ length: UInt64) {
        receivedContentLength += length
        updateDownloadProgress()
    }

    func showExtracting() {
        updatePhase(.extracting, showsCancel: false, resetProgress: true)
    }

    func updateExtractionProgress(_ progress: Double) {
        var next = model
        next.progressFraction = min(1, max(0, progress))
        next.progressText = formatPercent(next.progressFraction)
        model = next
    }

    func showReadyToInstall(reply: @escaping (SPUUserUpdateChoice) -> Void) {
        replyHandler = reply
        updatePhase(.readyToInstall, showsCancel: false, resetProgress: true)
    }

    func showInstalling() {
        updatePhase(.installing, showsCancel: false, resetProgress: true)
    }

    func chooseInstall() {
        replyHandler?(.install)
        replyHandler = nil
    }

    func chooseSkip() {
        replyHandler?(.skip)
        replyHandler = nil
        dismiss()
    }

    func chooseLater() {
        replyHandler?(.dismiss)
        replyHandler = nil
        dismiss()
    }

    func cancelOperation() {
        cancellationHandler?()
        cancellationHandler = nil
        dismiss()
    }

    func openInfoURL() {
        if let url = model.infoURL {
            NSWorkspace.shared.open(url)
        }
        chooseLater()
    }

    func bringToFront() {
        presentWindow()
    }

    func dismiss() {
        window?.orderOut(nil)
        isVisible = false
    }

    func windowWillClose(_ notification: Notification) {
        if model.phase == .checking, cancellationHandler != nil {
            cancelOperation()
            return
        }
        if replyHandler != nil {
            chooseLater()
            return
        }
        dismiss()
    }

    private func updatePhase(_ phase: UpdateWindowModel.Phase, showsCancel: Bool, resetProgress: Bool) {
        let appcastItem = lastAppcastItem
        let state = lastUserState
        var next = makeModel(for: phase, appcastItem: appcastItem, state: state)
        next.releaseNotes = model.releaseNotes
        next.releaseNotesError = model.releaseNotesError
        if resetProgress {
            next.progressFraction = nil
            next.progressText = nil
        } else {
            next.progressFraction = model.progressFraction
            next.progressText = model.progressText
        }
        next.showsCancel = showsCancel
        model = next
        presentWindow()
    }

    private func updateDownloadProgress() {
        guard expectedContentLength > 0 else { return }
        let fraction = Double(receivedContentLength) / Double(expectedContentLength)
        var next = model
        next.progressFraction = min(1, max(0, fraction))
        next.progressText = formatPercent(next.progressFraction)
        if next.fileSize == nil {
            next.fileSize = formattedFileSize(expectedContentLength)
        }
        model = next
    }

    private func makeModel(for phase: UpdateWindowModel.Phase, appcastItem: SUAppcastItem?, state: SPUUserUpdateState?) -> UpdateWindowModel {
        let currentVersion = currentAppVersionDisplay()
        let newVersion = appcastItem.map { appcastVersionDisplay($0) }
        let subtitle: String
        switch phase {
        case .checking:
            subtitle = ""
        default:
            let newVersionDisplay = newVersion ?? currentVersion
            subtitle = L10n.updateAvailableSubtitle(newVersionDisplay, currentVersion)
        }
        let title: String
        switch phase {
        case .checking:
            title = L10n.updateCheckingTitle
        case .available:
            title = L10n.updateAvailableTitle
        case .downloading:
            title = L10n.updateDownloadingTitle
        case .extracting:
            title = L10n.updatePreparingTitle
        case .readyToInstall:
            title = L10n.updateReadyTitle
        case .installing:
            title = L10n.updateInstallingTitle
        }

        let isInformationOnly = appcastItem?.isInformationOnlyUpdate ?? false
        let isCritical = appcastItem?.isCriticalUpdate ?? false
        let infoURL = appcastItem?.infoURL ?? appcastItem?.releaseNotesURL ?? appcastItem?.fullReleaseNotesURL
        let fileSize = appcastItem?.contentLength ?? expectedContentLength
        let primaryActionTitle: String? = {
            if phase == .available || phase == .readyToInstall {
                if isInformationOnly {
                    return L10n.updateLearnMore
                }
                if state?.stage == .downloaded || phase == .readyToInstall {
                    return L10n.updateInstallAndRelaunch
                }
                return L10n.updateDownload
            }
            return nil
        }()

        return UpdateWindowModel(
            phase: phase,
            title: title,
            subtitle: subtitle,
            currentVersion: phase == .checking ? nil : currentVersion,
            newVersion: phase == .checking ? nil : newVersion,
            fileSize: fileSize > 0 ? formattedFileSize(fileSize) : nil,
            isCritical: isCritical,
            isInformationOnly: isInformationOnly,
            infoURL: infoURL,
            releaseNotes: nil,
            releaseNotesError: nil,
            progressFraction: nil,
            progressText: nil,
            primaryActionTitle: primaryActionTitle,
            showsCancel: phase == .checking
        )
    }

    private func presentWindow() {
        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(origin: .zero, size: defaultWindowSize),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.minSize = defaultWindowSize
            panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
            panel.standardWindowButton(.zoomButton)?.isHidden = true
            panel.isReleasedWhenClosed = false
            panel.delegate = self
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let hosting = NSHostingController(rootView: UpdateWindowView(presenter: self))
            hosting.view.frame = NSRect(origin: .zero, size: defaultWindowSize)
            panel.contentViewController = hosting
            panel.setContentSize(defaultWindowSize)
            panel.center()
            window = panel
        } else if let panel = window {
            panel.setContentSize(defaultWindowSize)
        }

        isVisible = true
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func currentAppVersionDisplay() -> String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        if buildVersion.isEmpty || buildVersion == shortVersion {
            return shortVersion
        }
        return "\(shortVersion) (\(buildVersion))"
    }

    private func appcastVersionDisplay(_ item: SUAppcastItem) -> String {
        let display = item.displayVersionString
        let build = item.versionString
        if build.isEmpty || build == display {
            return display
        }
        return "\(display) (\(build))"
    }

    private func parseReleaseNotes(_ downloadData: SPUDownloadData) -> ReleaseNotesContent? {
        let data = downloadData.data
        let text = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
        let mimeType = downloadData.mimeType?.lowercased() ?? ""
        if mimeType.contains("html") || text.contains("<html") || text.contains("<body") {
            return .html(text, baseURL: downloadData.url)
        }
        return .text(text)
    }

    private func formattedFileSize(_ length: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(length), countStyle: .file)
    }

    private func formatPercent(_ value: Double?) -> String? {
        guard let value else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value))
    }
}

final class MoodistUpdateUserDriver: NSObject, SPUUserDriver {
    private let presenter: UpdateWindowPresenter

    init(presenter: UpdateWindowPresenter) {
        self.presenter = presenter
    }

    func show(_ _: SPUUpdatePermissionRequest, reply: @escaping @Sendable (SUUpdatePermissionResponse) -> Void) {
        Task { @MainActor in
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? L10n.appName
            let alert = NSAlert()
            alert.messageText = L10n.updatePermissionTitle
            alert.informativeText = L10n.updatePermissionMessage(appName)
            alert.addButton(withTitle: L10n.updatePermissionEnable)
            alert.addButton(withTitle: L10n.updatePermissionNotNow)
            let response = alert.runModal()
            let allow = response == .alertFirstButtonReturn
            reply(SUUpdatePermissionResponse(automaticUpdateChecks: allow, sendSystemProfile: false))
        }
    }

    func showUserInitiatedUpdateCheck(cancellation: @escaping @Sendable () -> Void) {
        Task { @MainActor in
            presenter.showChecking(cancellation: cancellation)
        }
    }

    func showUpdateFound(with appcastItem: SUAppcastItem, state: SPUUserUpdateState, reply: @escaping @Sendable (SPUUserUpdateChoice) -> Void) {
        Task { @MainActor in
            presenter.showUpdateFound(appcastItem: appcastItem, state: state, reply: reply)
        }
    }

    func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
        Task { @MainActor in
            presenter.updateReleaseNotes(with: downloadData)
        }
    }

    func showUpdateReleaseNotesFailedToDownloadWithError(_ error: any Error) {
        Task { @MainActor in
            presenter.updateReleaseNotesFailed(error)
        }
    }

    func showUpdateNotFoundWithError(_ error: any Error, acknowledgement: @escaping @Sendable () -> Void) {
        Task { @MainActor in
            let alert = NSAlert(error: error)
            alert.runModal()
            presenter.dismiss()
            acknowledgement()
        }
    }

    func showUpdaterError(_ error: any Error, acknowledgement: @escaping @Sendable () -> Void) {
        Task { @MainActor in
            let alert = NSAlert(error: error)
            alert.runModal()
            presenter.dismiss()
            acknowledgement()
        }
    }

    func showDownloadInitiated(cancellation: @escaping @Sendable () -> Void) {
        Task { @MainActor in
            presenter.showDownloading(cancellation: cancellation)
        }
    }

    func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
        Task { @MainActor in
            presenter.updateExpectedContentLength(expectedContentLength)
        }
    }

    func showDownloadDidReceiveData(ofLength length: UInt64) {
        Task { @MainActor in
            presenter.updateReceivedData(length)
        }
    }

    func showDownloadDidStartExtractingUpdate() {
        Task { @MainActor in
            presenter.showExtracting()
        }
    }

    func showExtractionReceivedProgress(_ progress: Double) {
        Task { @MainActor in
            presenter.updateExtractionProgress(progress)
        }
    }

    func showReady(toInstallAndRelaunch reply: @escaping @Sendable (SPUUserUpdateChoice) -> Void) {
        Task { @MainActor in
            presenter.showReadyToInstall(reply: reply)
        }
    }

    func showInstallingUpdate(withApplicationTerminated _: Bool, retryTerminatingApplication _: @escaping @Sendable () -> Void) {
        Task { @MainActor in
            presenter.showInstalling()
        }
    }

    func showUpdateInstalledAndRelaunched(_ _: Bool, acknowledgement: @escaping @Sendable () -> Void) {
        Task { @MainActor in
            presenter.dismiss()
            acknowledgement()
        }
    }

    func dismissUpdateInstallation() {
        Task { @MainActor in
            presenter.dismiss()
        }
    }

    func showUpdateInFocus() {
        Task { @MainActor in
            presenter.bringToFront()
        }
    }
}
