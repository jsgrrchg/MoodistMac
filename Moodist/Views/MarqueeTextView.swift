//
//  MarqueeTextView.swift
//  MoodistMac
//
//  Core Animation marquee for lower CPU usage.
//

import SwiftUI
import AppKit

struct MarqueeTextView: NSViewRepresentable {
    let text: String
    let font: NSFont
    let color: NSColor
    let speed: CGFloat
    let spacing: CGFloat
    let containerWidth: CGFloat
    let isEnabled: Bool

    func makeNSView(context: Context) -> MarqueeTextHostView {
        MarqueeTextHostView()
    }

    func updateNSView(_ nsView: MarqueeTextHostView, context: Context) {
        nsView.configure(
            text: text,
            font: font,
            color: color,
            speed: speed,
            spacing: spacing,
            containerWidth: containerWidth,
            isEnabled: isEnabled
        )
    }
}

final class MarqueeTextHostView: NSView {
    private let trackLayer = CALayer()
    private let textLayerA = CATextLayer()
    private let textLayerB = CATextLayer()

    private var currentText: String = ""
    private var currentFont: NSFont = .systemFont(ofSize: 14)
    private var currentColor: NSColor = .labelColor
    private var currentSpeed: CGFloat = 25
    private var currentSpacing: CGFloat = 48
    private var currentContainerWidth: CGFloat = 0
    private var currentIsEnabled: Bool = false
    private var lastCycleWidth: CGFloat = 0
    private var lastSpeed: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.clear.cgColor

        trackLayer.frame = bounds
        layer?.addSublayer(trackLayer)

        configureTextLayer(textLayerA)
        configureTextLayer(textLayerB)
        trackLayer.addSublayer(textLayerA)
        trackLayer.addSublayer(textLayerB)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(
        text: String,
        font: NSFont,
        color: NSColor,
        speed: CGFloat,
        spacing: CGFloat,
        containerWidth: CGFloat,
        isEnabled: Bool
    ) {
        currentText = text
        currentFont = font
        currentColor = color
        currentSpeed = max(1, speed)
        currentSpacing = max(0, spacing)
        currentContainerWidth = containerWidth
        currentIsEnabled = isEnabled
        needsLayout = true
    }

    override func layout() {
        super.layout()
        trackLayer.frame = bounds
        updateLayers()
    }

    private func configureTextLayer(_ layer: CATextLayer) {
        layer.contentsScale = window?.backingScaleFactor ?? 2
        layer.alignmentMode = .left
        layer.isWrapped = false
        layer.truncationMode = .end
        layer.backgroundColor = NSColor.clear.cgColor
    }

    private func updateLayers() {
        let boundsWidth = bounds.width
        guard boundsWidth > 0 else { return }

        let textSize = measureText()
        let availableWidth = currentContainerWidth > 0 ? currentContainerWidth : boundsWidth
        let shouldScroll = currentIsEnabled && textSize.width > availableWidth

        let textY = max(0, (bounds.height - textSize.height) * 0.5)
        let attributes = textAttributes()
        let attributed = NSAttributedString(string: currentText, attributes: attributes)

        textLayerA.string = attributed
        textLayerA.foregroundColor = currentColor.cgColor
        textLayerB.string = attributed
        textLayerB.foregroundColor = currentColor.cgColor

        textLayerA.contentsScale = window?.backingScaleFactor ?? 2
        textLayerB.contentsScale = window?.backingScaleFactor ?? 2

        if shouldScroll {
            let cycleWidth = textSize.width + currentSpacing
            textLayerA.frame = CGRect(x: 0, y: textY, width: textSize.width, height: textSize.height)
            textLayerB.frame = CGRect(x: cycleWidth, y: textY, width: textSize.width, height: textSize.height)
            textLayerB.isHidden = false
            startAnimation(cycleWidth: cycleWidth)
        } else {
            stopAnimation()
            // Keep baseline visually centered to match the scrolling layout.
            textLayerA.frame = CGRect(x: 0, y: textY, width: bounds.width, height: textSize.height)
            textLayerB.isHidden = true
        }
    }

    private func measureText() -> CGSize {
        let attributes = textAttributes()
        let size = (currentText as NSString).size(withAttributes: attributes)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    private func textAttributes() -> [NSAttributedString.Key: Any] {
        [
            .font: currentFont,
            .foregroundColor: currentColor
        ]
    }

    private func startAnimation(cycleWidth: CGFloat) {
        if trackLayer.animation(forKey: "marquee") != nil,
           abs(lastCycleWidth - cycleWidth) < 0.5,
           abs(lastSpeed - currentSpeed) < 0.5 {
            return
        }
        trackLayer.removeAnimation(forKey: "marquee")
        let duration = Double(cycleWidth / currentSpeed)
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = 0
        animation.toValue = -cycleWidth
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        trackLayer.add(animation, forKey: "marquee")
        lastCycleWidth = cycleWidth
        lastSpeed = currentSpeed
    }

    private func stopAnimation() {
        trackLayer.removeAnimation(forKey: "marquee")
        lastCycleWidth = 0
        lastSpeed = 0
    }
}
