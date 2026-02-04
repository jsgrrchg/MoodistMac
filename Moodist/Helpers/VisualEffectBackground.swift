//
//  VisualEffectBackground.swift
//  MoodistMac
//
//  Fondo con vibrancy/transparencia para macOS (NSVisualEffectView).
//  En macOS 26+ se puede combinar con Liquid Glass; aquí se usa para versiones anteriores.
//

import SwiftUI
import AppKit

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
