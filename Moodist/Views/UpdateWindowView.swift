//
//  UpdateWindowView.swift
//  MoodistMac
//
//  UI para la ventana de actualizaciones (Sparkle custom user driver).
//

import AppKit
import SwiftUI
import WebKit

struct UpdateWindowView: View {
    @ObservedObject var presenter: UpdateWindowPresenter
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparencyEnabled = true

    private var accent: Color { MoodistTheme.Colors.accent }

    var body: some View {
        ZStack {
            background
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var background: some View {
        ZStack {
            if transparencyEnabled {
                VisualEffectBackground(material: .underWindowBackground, blendingMode: .behindWindow)
            } else {
                MoodistTheme.Colors.windowBackground
            }
            LinearGradient(
                colors: [accent.opacity(0.08), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.softLight)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
                .opacity(colorScheme == .dark ? 0.4 : 0.25)
            releaseNotesCard
            statusSection
            actionRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            appIcon

            VStack(alignment: .leading, spacing: 6) {
                Text(presenter.model.title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                if !presenter.model.subtitle.isEmpty {
                    Text(presenter.model.subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if presenter.model.phase != .checking {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], alignment: .leading, spacing: 8) {
                        if let newVersion = presenter.model.newVersion {
                            UpdateMetaChip(title: L10n.updateNewVersion, value: newVersion)
                        }
                        if let currentVersion = presenter.model.currentVersion {
                            UpdateMetaChip(title: L10n.updateCurrentVersion, value: currentVersion)
                        }
                        if let size = presenter.model.fileSize {
                            UpdateMetaChip(title: L10n.updateSize, value: size)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            if presenter.model.isCritical {
                CriticalBadge()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var releaseNotesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.updateReleaseNotesTitle)
                .font(.subheadline.weight(.semibold))
            UpdateReleaseNotesView(
                notes: presenter.model.releaseNotes,
                errorText: presenter.model.releaseNotesError,
                accentHex: accent.hexString,
                colorScheme: colorScheme
            )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
        .frame(minHeight: 200, idealHeight: 230, maxHeight: 260)
        .background(notesBackground)
        .overlay(notesBorder)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusSection: some View {
        Group {
            if shouldShowProgress {
                VStack(alignment: .leading, spacing: 6) {
                    if let value = presenter.model.progressFraction {
                        ProgressView(value: value)
                            .progressViewStyle(.linear)
                    } else {
                        ProgressView()
                            .progressViewStyle(.linear)
                    }

                    if let text = presenter.model.progressText {
                        Text(text)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionRow: some View {
        ViewThatFits(in: .horizontal) {
            actionRowLayout(isVertical: false)
            actionRowLayout(isVertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shouldShowProgress: Bool {
        switch presenter.model.phase {
        case .checking, .downloading, .extracting, .installing:
            return true
        case .available, .readyToInstall:
            return false
        }
    }

    private var appIcon: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.18), radius: 8, x: 0, y: 4)
    }

    private var notesBackground: some View {
        let base = colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.035)
        return RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(base)
    }

    private var notesBorder: some View {
        let border = colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
        return RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(border, lineWidth: 1)
    }

    @ViewBuilder
    private func actionRowLayout(isVertical: Bool) -> some View {
        let spacing = isVertical ? 10.0 : 8.0

        let content: AnyView = {
            switch presenter.model.phase {
            case .checking:
                return AnyView(
                    Group {
                        if isVertical {
                            VStack(alignment: .leading, spacing: spacing) {
                                actionButton(L10n.cancel, fillWidth: true) { presenter.cancelOperation() }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack(spacing: spacing) {
                                actionButton(L10n.cancel, fillWidth: false) { presenter.cancelOperation() }
                                Spacer()
                            }
                        }
                    }
                )
            case .available, .readyToInstall:
                if presenter.model.isInformationOnly {
                    return AnyView(
                        Group {
                            if isVertical {
                                VStack(alignment: .leading, spacing: spacing) {
                                    actionButton(L10n.updateLater, fillWidth: true) { presenter.chooseLater() }
                                    actionButton(L10n.updateLearnMore, isPrimary: true, fillWidth: true) { presenter.openInfoURL() }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                HStack(spacing: spacing) {
                                    actionButton(L10n.updateLater, fillWidth: false) { presenter.chooseLater() }
                                    Spacer()
                                    actionButton(L10n.updateLearnMore, isPrimary: true, fillWidth: false) { presenter.openInfoURL() }
                                }
                            }
                        }
                    )
                } else {
                    return AnyView(
                        Group {
                            if isVertical {
                                VStack(alignment: .leading, spacing: spacing) {
                                    if !presenter.model.isCritical {
                                        actionButton(L10n.updateSkip, fillWidth: true) { presenter.chooseSkip() }
                                    }
                                    actionButton(L10n.updateLater, fillWidth: true) { presenter.chooseLater() }
                                    actionButton(presenter.model.primaryActionTitle ?? L10n.updateDownload, isPrimary: true, fillWidth: true) {
                                        presenter.chooseInstall()
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                HStack(spacing: spacing) {
                                    if !presenter.model.isCritical {
                                        actionButton(L10n.updateSkip, fillWidth: false) { presenter.chooseSkip() }
                                    }
                                    actionButton(L10n.updateLater, fillWidth: false) { presenter.chooseLater() }
                                    Spacer()
                                    actionButton(presenter.model.primaryActionTitle ?? L10n.updateDownload, isPrimary: true, fillWidth: false) {
                                        presenter.chooseInstall()
                                    }
                                }
                            }
                        }
                    )
                }
            case .downloading, .extracting, .installing:
                return AnyView(
                    Group {
                        if isVertical {
                            VStack(alignment: .leading, spacing: spacing) {
                                if presenter.model.showsCancel {
                                    actionButton(L10n.cancel, fillWidth: true) { presenter.cancelOperation() }
                                }
                                actionButton(L10n.close, fillWidth: true) { presenter.dismiss() }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack(spacing: spacing) {
                                if presenter.model.showsCancel {
                                    actionButton(L10n.cancel, fillWidth: false) { presenter.cancelOperation() }
                                }
                                Spacer()
                                actionButton(L10n.close, fillWidth: false) { presenter.dismiss() }
                            }
                        }
                    }
                )
            }
        }()

        content
            .controlSize(.large)
    }

    @ViewBuilder
    private func actionButton(_ title: String, isPrimary: Bool = false, fillWidth: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(UpdateActionButtonStyle(isPrimary: isPrimary, accent: accent))
            .frame(maxWidth: fillWidth ? .infinity : nil)
    }
}

private struct UpdateActionButtonStyle: ButtonStyle {
    let isPrimary: Bool
    let accent: Color
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let baseFill = isPrimary ? accent : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
        let borderColor = colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.12)
        let pressOpacity = configuration.isPressed ? 0.8 : 1.0
        let textColor: Color = {
            if isPrimary {
                return .white
            }
            return colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.85)
        }()

        return configuration.label
            .font(.system(size: 13.5, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(minHeight: 28)
            .foregroundStyle(textColor)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(baseFill.opacity(pressOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isPrimary ? Color.clear : borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isPrimary ? 0.18 : 0.08), radius: 4, x: 0, y: 2)
    }
}

private struct UpdateMetaChip: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
        )
    }
}

private struct CriticalBadge: View {
    var body: some View {
        Text(L10n.updateCritical.uppercased())
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.red.opacity(0.85))
            )
            .foregroundStyle(.white)
    }
}

private struct UpdateReleaseNotesView: View {
    let notes: ReleaseNotesContent?
    let errorText: String?
    let accentHex: String
    let colorScheme: ColorScheme

    var body: some View {
        if let notes {
            switch notes {
            case .html(let html, let baseURL):
                UpdateHTMLView(html: html, baseURL: baseURL, accentHex: accentHex, colorScheme: colorScheme)
            case .text(let text):
                UpdatePlainNotesView(text: text)
            }
        } else if let errorText {
            Text(errorText)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 8) {
                ProgressView()
                Text(L10n.updateNotesLoading)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct UpdatePlainNotesView: View {
    let text: String

    var body: some View {
        ScrollView {
            if let bullets = bulletItems(from: text) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(bullets, id: \.self) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color.secondary.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)
                            Text(item)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.bottom, 8)
            } else {
                Text(text)
                    .font(.body)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
            }
        }
        .textSelection(.enabled)
    }

    private func bulletItems(from text: String) -> [String]? {
        let lines = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard lines.count >= 2 else { return nil }
        let normalized = lines.compactMap { line -> String? in
            if line.hasPrefix("- ") {
                return String(line.dropFirst(2))
            }
            if line.hasPrefix("• ") {
                return String(line.dropFirst(2))
            }
            return nil
        }
        return normalized.count == lines.count ? normalized : nil
    }
}

private struct UpdateHTMLView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    let accentHex: String
    let colorScheme: ColorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = false
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let themedHTML = themedHTMLString()
        if context.coordinator.lastHTML != themedHTML {
            webView.loadHTMLString(themedHTML, baseURL: baseURL)
            context.coordinator.lastHTML = themedHTML
        }
    }

    final class Coordinator {
        var lastHTML: String?
    }

    private func themedHTMLString() -> String {
        let isDark = colorScheme == .dark
        let bodyColor = isDark ? "#F5F5F7" : "#111111"
        let secondary = isDark ? "#B5B5B8" : "#4A4A4A"
        let background = "transparent"
        let style = """
        <style>
        :root { color-scheme: \(isDark ? "dark" : "light"); }
        body { margin: 0; padding: 0; font: 15px -apple-system, BlinkMacSystemFont, \"SF Pro Text\"; color: \(bodyColor); background: \(background); }
        a { color: \(accentHex); }
        h1, h2, h3 { margin: 0 0 0.6em 0; font-weight: 600; }
        p { margin: 0 0 0.8em 0; line-height: 1.5; }
        ul { margin: 0.2em 0 0.8em 1.1em; padding: 0; }
        li { margin: 0 0 0.4em 0; }
        small, .muted { color: \(secondary); }
        img { max-width: 100%; height: auto; border-radius: 10px; }
        </style>
        """

        let lower = html.lowercased()
        if lower.contains("<html") {
            return html.replacingOccurrences(of: "</head>", with: "\(style)</head>", options: .caseInsensitive)
        }
        return """
        <!doctype html>
        <html>
        <head>\(style)</head>
        <body>\(html)</body>
        </html>
        """
    }
}
