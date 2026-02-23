//
//  ToolbarBridges.swift
//  MoodistMac
//
//  AppKit bridges used by the toolbar.
//

import SwiftUI
import AppKit

struct TitlebarDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DraggableTitlebarView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DraggableTitlebarView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }
}

/// Barra de búsqueda nativa de macOS (NSSearchField con estilo estándar de Apple).
struct ToolbarSearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    @Binding var requestFocus: Bool
    let height: CGFloat

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField(string: "")
        field.delegate = context.coordinator
        field.controlSize = .small
        field.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        field.sendsSearchStringImmediately = true
        field.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = field.heightAnchor.constraint(equalToConstant: height)
        heightConstraint.isActive = true
        context.coordinator.heightConstraint = heightConstraint
        if #available(macOS 26.0, *) {
            field.focusRingType = .none
        } else {
            field.focusRingType = .default
        }

        if let cell = field.cell as? NSSearchFieldCell {
            cell.controlSize = .small
            cell.bezelStyle = .roundedBezel
        }
        field.placeholderString = placeholder
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        context.coordinator.heightConstraint?.constant = height
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        if requestFocus {
            nsView.window?.makeFirstResponder(nsView)
            DispatchQueue.main.async {
                requestFocus = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        private let parent: ToolbarSearchField
        var heightConstraint: NSLayoutConstraint?

        init(_ parent: ToolbarSearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            parent.text = field.stringValue
        }
    }
}
