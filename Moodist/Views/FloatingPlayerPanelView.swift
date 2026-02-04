//
//  FloatingPlayerPanelView.swift
//  MoodistMac
//
//  Barra flotante del reproductor con Liquid Glass (macOS 26+) o NSVisualEffectView (versiones anteriores).
//

import SwiftUI
import AppKit

/// Forma redondeada sutil para el reproductor (estilo Liquid Glass / Apple Music)
private let floatingBarShape = RoundedRectangle(
    cornerRadius: 12,
    style: .continuous
)

/// Ratio de ancho en ventanas grandes (tipo Apple Music)
private let floatingBarWidthRatioNormal: CGFloat = 0.88
/// Ratio en ventanas angostas: la barra usa casi todo el ancho disponible
private let floatingBarWidthRatioNarrow: CGFloat = 0.96
/// Ancho de ventana por debajo del cual se usa ratio “narrow”
private let narrowWindowThreshold: CGFloat = 420
/// Ancho mínimo de la barra para ventanas muy angostas (el contenido se comprime con minWidth en slider/título)
private let floatingBarMinWidth: CGFloat = 220
private let floatingBarMaxWidth: CGFloat = 900
/// Margen inferior desde el borde de la ventana
private let floatingBarBottomMargin: CGFloat = 12
/// Margen horizontal; en ventanas angostas se reduce
private let floatingBarHorizontalMarginNormal: CGFloat = 20
private let floatingBarHorizontalMarginNarrow: CGFloat = 10
/// Altura compacta de la barra (estilo reproductor mínimo)
private let floatingBarHeight: CGFloat = 52
/// Umbral por debajo del cual se usa layout compacto
private let compactLayoutThreshold: CGFloat = 380
/// Umbral por debajo del cual se usa layout minimal (muy angosto)
private let minimalLayoutThreshold: CGFloat = 300
/// Ancho mínimo del slider de volumen para que se comprima en ventanas muy angostas
private let sliderMinWidth: CGFloat = 32
/// Espaciado entre zonas (icono+controles | título | volumen) para una disposición clara
private let barZoneSpacing: CGFloat = 20

/// Velocidad del marquesina (puntos por segundo)
private let marqueeSpeed: CGFloat = 25
/// Intervalo de refresco para marquesina SwiftUI (fallback)
#if !os(macOS)
private let marqueeTickInterval: TimeInterval = 0.06
#endif

private struct TextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Título que se desplaza en horizontal cuando no cabe (estilo reproductor clásico).
private struct MarqueeLabel: View {
    let text: String
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let color: Color
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
                    MarqueeTextView(
                        text: text,
                        font: NSFont.systemFont(ofSize: fontSize, weight: fontWeight.toNSFontWeight()),
                        color: NSColor(color),
                        speed: marqueeSpeed,
                        spacing: spacing,
                        containerWidth: containerWidth,
                        isEnabled: shouldScroll
                    )
                    #else
                    TimelineView(.periodic(from: .now, by: marqueeTickInterval)) { context in
                        let cycleWidth = measuredTextWidth + spacing
                        let elapsed = context.date.timeIntervalSinceReferenceDate
                        let offset = (-CGFloat(elapsed) * marqueeSpeed).truncatingRemainder(dividingBy: cycleWidth)
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
                    MarqueeTextView(
                        text: text,
                        font: NSFont.systemFont(ofSize: fontSize, weight: fontWeight.toNSFontWeight()),
                        color: NSColor(color),
                        speed: marqueeSpeed,
                        spacing: spacing,
                        containerWidth: containerWidth,
                        isEnabled: false
                    )
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
                .background(GeometryReader { g in
                    Color.clear.preference(key: TextWidthKey.self, value: g.size.width)
                })
                .allowsHitTesting(false)
        }
        .onPreferenceChange(TextWidthKey.self) { measuredTextWidth = $0 }
    }
}

private extension Font.Weight {
    func toNSFontWeight() -> NSFont.Weight {
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
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparencyEnabled = true

    private var displayLabel: String {
        store.displayedMixName ?? (store.hasSelection ? L10n.customMix : L10n.noSoundsPlaying)
    }

    private var displayIconName: String {
        store.displayedMixIconName ?? "waveform"
    }

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let isNarrow = availableWidth < narrowWindowThreshold
            let horizontalMargin = isNarrow ? floatingBarHorizontalMarginNarrow : floatingBarHorizontalMarginNormal
            let barWidth = barTargetWidth(availableWidth: availableWidth, horizontalMargin: horizontalMargin)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    floatingBarContainer
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
        let ratio = usableWidth < narrowWindowThreshold ? floatingBarWidthRatioNarrow : floatingBarWidthRatioNormal
        let proportionalWidth = usableWidth * ratio
        return min(max(proportionalWidth, floatingBarMinWidth), min(usableWidth, floatingBarMaxWidth))
    }

    private func barContent(availableWidth: CGFloat) -> some View {
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
                // Zona izquierda: botón tipo “portada” (icono) + controles de reproducción
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
                            .font(.system(size: isMinimal ? 13 : (isCompact ? 14 : 16), weight: .medium))
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

            // Zona central: título del mix (marquesina si no cabe)
            MarqueeLabel(
                text: displayLabel,
                fontSize: titleFontSize,
                fontWeight: titleFontWeight,
                color: MoodistTheme.Colors.secondaryText
            )
            .layoutPriority(0)

            // Zona derecha: volumen (altavoz + slider), fondo opaco para que la marquesina no se trasluzca
            HStack(alignment: .center, spacing: volumeSpacing) {
                Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: isMinimal ? 8 : (isCompact ? 9 : 11)))
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .frame(width: isMinimal ? 14 : 18, alignment: .center)
                volumeSlider(isMinimal: isMinimal)
                .frame(minWidth: sliderMinWidth, maxWidth: sliderWidth)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(PlatformColor.windowBackground)
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

    @ViewBuilder private var floatingBarContainer: some View {
        #if LIQUID_GLASS_SDK
        if #available(macOS 26.0, *) {
            if transparencyEnabled {
                // Liquid Glass (Adopting Liquid Glass): material translúcido que deja ver el contenido detrás
                ZStack {
                    floatingBarShape
                        .fill(Color.clear)
                        .glassEffect(.regular.interactive(), in: floatingBarShape)
                        .opacity(0.85)
                    GeometryReader { g in barContent(availableWidth: g.size.width) }
                }
                .clipShape(floatingBarShape)
                .contentShape(floatingBarShape)
                .allowsHitTesting(true)
                .overlay(barOverlay)
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            } else {
                solidBarContainer
            }
        } else {
            if transparencyEnabled {
                fallbackBarContainer
            } else {
                solidBarContainer
            }
        }
        #else
        if transparencyEnabled {
            fallbackBarContainer
        } else {
            solidBarContainer
        }
        #endif
    }
    
    private var fallbackBarContainer: some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blendingMode: .withinWindow)
                .opacity(0.85)
                .clipShape(floatingBarShape)
            GeometryReader { g in barContent(availableWidth: g.size.width) }
        }
        .clipShape(floatingBarShape)
        .contentShape(floatingBarShape)
        .allowsHitTesting(true)
        .overlay(barOverlay)
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
    
    private var solidBarContainer: some View {
        ZStack {
            floatingBarShape
                .fill(PlatformColor.windowBackground)
            GeometryReader { g in barContent(availableWidth: g.size.width) }
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
