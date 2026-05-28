//
//  FloatingPlayerPanelView.swift
//  MoodistMac
//
//  Floating player bar using Liquid Glass on macOS 26+ or NSVisualEffectView on earlier versions.
//

import AppKit
import SwiftUI

/// Subtle rounded shape for the player.
private let floatingBarShape = RoundedRectangle(
    cornerRadius: 12,
    style: .continuous
)

/// Width ratio for large windows, similar to Apple Music.
private let floatingBarWidthRatioNormal: CGFloat = 0.88
/// Width ratio for narrow windows, where the bar uses most available width.
private let floatingBarWidthRatioNarrow: CGFloat = 0.96
/// Window width below which the narrow ratio is used.
private let narrowWindowThreshold: CGFloat = 420
/// Minimum bar width for very narrow windows, with content compressed by slider/title minWidth.
private let floatingBarMinWidth: CGFloat = 220
private let floatingBarMaxWidth: CGFloat = 900
/// Bottom margin from the window edge.
private let floatingBarBottomMargin: CGFloat = 12
/// Horizontal margin, reduced in narrow windows.
private let floatingBarHorizontalMarginNormal: CGFloat = 20
private let floatingBarHorizontalMarginNarrow: CGFloat = 10
/// Compact bar height for the minimal player style.
private let floatingBarHeight: CGFloat = 52
/// Threshold below which compact layout is used.
private let compactLayoutThreshold: CGFloat = 380
/// Threshold below which minimal layout is used.
private let minimalLayoutThreshold: CGFloat = 300
/// Minimum volume slider width so it can compress in very narrow windows.
private let sliderMinWidth: CGFloat = 32
/// Spacing between zones: icon and controls, title, and volume.
private let barZoneSpacing: CGFloat = 20

/// Marquee speed in points per second.
private let marqueeSpeed: CGFloat = 25
/// Refresh interval for the SwiftUI marquee fallback.
#if !os(macOS)
    private let marqueeTickInterval: TimeInterval = 0.06
#endif

private struct TextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Title that scrolls horizontally when it does not fit, like a classic player.
private struct MarqueeLabel: View {
    let text: String
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    @State private var measuredTextWidth: CGFloat = 0

    var body: some View {
        let swiftUIFont = Font.system(size: fontSize, weight: fontWeight)
        GeometryReader { geo in
            let containerWidth = geo.size.width
            let spacing: CGFloat = 48
            let shouldScroll = measuredTextWidth > 0 && measuredTextWidth > containerWidth

            ZStack(alignment: .leading) {
                if shouldScroll {
                    #if os(macOS)
                        let marqueeNSColor: NSColor =
                            colorScheme == .dark
                            ? .white
                            : NSColor(calibratedWhite: 0.42, alpha: 1)
                        MarqueeTextView(
                            text: text,
                            font: NSFont.systemFont(
                                ofSize: fontSize, weight: fontWeight.toNSFontWeight()),
                            color: marqueeNSColor,
                            speed: marqueeSpeed,
                            spacing: spacing,
                            containerWidth: containerWidth,
                            isEnabled: shouldScroll,
                            colorScheme: colorScheme
                        )
                    #else
                        TimelineView(.periodic(from: .now, by: marqueeTickInterval)) { context in
                            let cycleWidth = measuredTextWidth + spacing
                            let elapsed = context.date.timeIntervalSinceReferenceDate
                            let offset = (-CGFloat(elapsed) * marqueeSpeed).truncatingRemainder(
                                dividingBy: cycleWidth)
                            HStack(spacing: spacing) {
                                Text(text)
                                    .font(swiftUIFont)
                                    .foregroundStyle(color)
                                    .lineLimit(1)
                                    .fixedSize()
                                Text(text)
                                    .font(swiftUIFont)
                                    .foregroundStyle(color)
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                            .offset(x: offset)
                        }
                    #endif
                } else {
                    #if os(macOS)
                        Text(text)
                            .font(swiftUIFont)
                            .foregroundStyle(color)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    #else
                        Text(text)
                            .font(swiftUIFont)
                            .foregroundStyle(color)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    #endif
                }
            }
            .frame(width: containerWidth, height: geo.size.height, alignment: .leading)
            .clipped()
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .leading) {
            Text(text)
                .font(swiftUIFont)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .hidden()
                .background(
                    GeometryReader { g in
                        Color.clear.preference(key: TextWidthKey.self, value: g.size.width)
                    }
                )
                .allowsHitTesting(false)
        }
        .onPreferenceChange(TextWidthKey.self) { measuredTextWidth = $0 }
    }
}

extension Font.Weight {
    fileprivate func toNSFontWeight() -> NSFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}

struct BottomPlayerBarView: View {
    @EnvironmentObject var store: SoundStore
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparencyEnabled = true

    /// White text in dark mode; secondary text in light mode.
    private var playerBarTextColor: Color {
        colorScheme == .dark ? .white : MoodistTheme.Colors.secondaryText
    }

    private var displayLabel: String {
        store.displayedMixName ?? (store.hasSelection ? L10n.customMix : L10n.noSoundsPlaying)
    }

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let isNarrow = availableWidth < narrowWindowThreshold
            let horizontalMargin =
                isNarrow ? floatingBarHorizontalMarginNarrow : floatingBarHorizontalMarginNormal
            let barWidth = barTargetWidth(
                availableWidth: availableWidth, horizontalMargin: horizontalMargin)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    floatingBarContainer(availableWidth: barWidth)
                        .frame(width: barWidth)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, horizontalMargin)
                .padding(.bottom, floatingBarBottomMargin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func barTargetWidth(availableWidth: CGFloat, horizontalMargin: CGFloat) -> CGFloat {
        let usableWidth = max(0, availableWidth - (horizontalMargin * 2))
        let ratio =
            usableWidth < narrowWindowThreshold
            ? floatingBarWidthRatioNarrow : floatingBarWidthRatioNormal
        let proportionalWidth = usableWidth * ratio
        return min(
            max(proportionalWidth, floatingBarMinWidth), min(usableWidth, floatingBarMaxWidth))
    }

    private func barContent(availableWidth: CGFloat, barTextColor: Color) -> some View {
        let isMinimal = availableWidth < minimalLayoutThreshold
        let isCompact = availableWidth < compactLayoutThreshold
        let controlSize: CGFloat = isMinimal ? 24 : (isCompact ? 28 : 32)
        let playSize: CGFloat = isMinimal ? 28 : (isCompact ? 32 : 36)
        let paddingH: CGFloat = isMinimal ? 6 : (isCompact ? 10 : 14)
        let sliderWidth: CGFloat = isMinimal ? 44 : (isCompact ? 56 : 92)
        let zoneSpacing: CGFloat = isMinimal ? 8 : (isCompact ? 12 : barZoneSpacing)
        let controlsInnerSpacing: CGFloat = isMinimal ? 2 : 4
        let volumeSpacing: CGFloat = isMinimal ? 4 : 8
        let verticalPadding: CGFloat = isMinimal ? 4 : 6
        let titleFontSize: CGFloat = isMinimal ? 12 : (isCompact ? 13 : 14.5)
        let titleFontWeight: Font.Weight = isMinimal ? .regular : .medium

        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(alignment: .center, spacing: zoneSpacing) {
                // Left zone: cover-style icon button plus playback controls.
                HStack(alignment: .center, spacing: controlsInnerSpacing) {
                    Button(action: { store.shuffle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: isMinimal ? 11 : (isCompact ? 12 : 14)))
                            .frame(width: controlSize, height: controlSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(L10n.shuffle)
                    .accessibilityLabel(L10n.shuffle)

                    Button(action: { store.unselectAll() }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: isMinimal ? 11 : (isCompact ? 12 : 14)))
                            .frame(width: controlSize, height: controlSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.hasSelection)
                    .help(L10n.unselectAll)
                    .accessibilityLabel(L10n.clear)

                    Button(action: { store.togglePlay() }) {
                        Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                            .font(
                                .system(
                                    size: isMinimal ? 13 : (isCompact ? 14 : 16), weight: .medium)
                            )
                            .frame(width: playSize, height: playSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.hasSelection)
                    .help(store.isPlaying ? L10n.pause : L10n.play)

                    Button(action: { store.playNextRandomMix() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: isMinimal ? 11 : (isCompact ? 12 : 14)))
                            .frame(width: controlSize, height: controlSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(L10n.nextMix)
                }

                // Center zone: mix title with marquee when it does not fit.
                MarqueeLabel(
                    text: displayLabel,
                    fontSize: titleFontSize,
                    fontWeight: titleFontWeight,
                    color: barTextColor
                )
                .layoutPriority(0)

                // Right zone: volume controls with an opaque background so the marquee does not show through.
                HStack(alignment: .center, spacing: volumeSpacing) {
                    Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: isMinimal ? 8 : (isCompact ? 9 : 11)))
                        .foregroundStyle(barTextColor)
                        .frame(width: isMinimal ? 14 : 18, alignment: .center)
                    volumeSlider(isMinimal: isMinimal)
                        .frame(minWidth: sliderMinWidth, maxWidth: sliderWidth)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .compositingGroup()
                .clipped()
                .frame(minWidth: sliderMinWidth + (isMinimal ? 18 : 24), alignment: .trailing)
                .accessibilityLabel(L10n.globalVolume)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, paddingH)
        .padding(.vertical, verticalPadding)
        .frame(height: floatingBarHeight)
        .frame(maxHeight: .infinity, alignment: .center)
        .frame(minWidth: 0, maxWidth: .infinity)
    }

    @ViewBuilder private func floatingBarContainer(availableWidth: CGFloat) -> some View {
        #if LIQUID_GLASS_SDK
            if #available(macOS 26.0, *) {
                if transparencyEnabled {
                    // Liquid Glass: .glassEffect applies the real glass effect on macOS 26.
                    barContent(availableWidth: availableWidth, barTextColor: .primary)
                        .glassEffect(in: .rect(cornerRadius: 12))
                        .contentShape(floatingBarShape)
                        .allowsHitTesting(true)
                } else {
                    solidBarContainer(availableWidth: availableWidth)
                }
            } else {
                if transparencyEnabled {
                    fallbackBarContainer(availableWidth: availableWidth)
                } else {
                    solidBarContainer(availableWidth: availableWidth)
                }
            }
        #else
            if transparencyEnabled {
                fallbackBarContainer(availableWidth: availableWidth)
            } else {
                solidBarContainer(availableWidth: availableWidth)
            }
        #endif
    }

    private func fallbackBarContainer(availableWidth: CGFloat) -> some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blendingMode: .withinWindow)
                .opacity(0.85)
                .clipShape(floatingBarShape)
            barContent(availableWidth: availableWidth, barTextColor: playerBarTextColor)
        }
        .clipShape(floatingBarShape)
        .contentShape(floatingBarShape)
        .allowsHitTesting(true)
        .overlay(barOverlay)
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private func solidBarContainer(availableWidth: CGFloat) -> some View {
        ZStack {
            floatingBarShape
                .fill(PlatformColor.windowBackground)
            barContent(availableWidth: availableWidth, barTextColor: playerBarTextColor)
        }
        .clipShape(floatingBarShape)
        .contentShape(floatingBarShape)
        .allowsHitTesting(true)
        .overlay(barOverlay)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    private var barOverlay: some View {
        floatingBarShape
            .strokeBorder(
                Color.primary.opacity(0.08),
                lineWidth: 0.5
            )
    }

    private var globalVolumeBinding: Binding<Double> {
        Binding(
            get: { store.globalVolume },
            set: { store.setGlobalVolume($0) }
        )
    }

    @ViewBuilder private func volumeSlider(isMinimal: Bool) -> some View {
        #if LIQUID_GLASS_SDK
            if #available(macOS 26.0, *), transparencyEnabled {
                Slider(value: globalVolumeBinding, in: 0...1)
                    .controlSize(isMinimal ? .mini : .small)
                    .tint(MoodistTheme.Colors.accent)
                    .frame(height: isMinimal ? 20 : 22)
                    .clipped()
                    .accessibilityValue("\(Int(store.globalVolume * 100))%")
            } else {
                ModernVolumeSlider(value: globalVolumeBinding, isMinimal: isMinimal)
            }
        #else
            ModernVolumeSlider(value: globalVolumeBinding, isMinimal: isMinimal)
        #endif
    }
}

private struct ModernVolumeSlider: View {
    @Binding var value: Double
    let isMinimal: Bool

    private var knobSize: CGFloat { isMinimal ? 10 : 12 }
    private var trackHeight: CGFloat { isMinimal ? 5 : 6 }

    var body: some View {
        let height = max(trackHeight, knobSize)
        GeometryReader { geo in
            let width = max(1, geo.size.width)
            let usable = max(1, width - knobSize)
            let clamped = min(1, max(0, value))
            let knobX = clamped * usable

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.16))
                    .frame(height: trackHeight)
                Capsule()
                    .fill(MoodistTheme.Colors.accent.opacity(0.85))
                    .frame(width: knobX + knobSize * 0.5, height: trackHeight)
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: knobSize, height: knobSize)
                    .shadow(color: Color.black.opacity(0.08), radius: 1.5, x: 0, y: 0.5)
                    .offset(x: knobX)
            }
            .frame(height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let location = max(0, min(gesture.location.x - knobSize * 0.5, usable))
                        value = Double(location / usable)
                    }
            )
        }
        .frame(height: height)
        .clipped()
        .accessibilityValue("\(Int(value * 100))%")
    }
}

#Preview {
    BottomPlayerBarView()
        .environmentObject(SoundStore(audioService: AudioService()))
        .padding()
}
