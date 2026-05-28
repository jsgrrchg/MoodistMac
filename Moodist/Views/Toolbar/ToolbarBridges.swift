//
//  ToolbarBridges.swift
//  MoodistMac
//
//  AppKit bridges used by the toolbar.
//

import AppKit
import SwiftUI

struct TitlebarDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DraggableTitlebarView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DraggableTitlebarView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }
}

/// Detects horizontal scrolling from a trackpad or Magic Mouse to switch sections.
struct HorizontalSectionSwipeDetector: NSViewRepresentable {
    let onSwipeToMixes: () -> Void
    let onSwipeToSounds: () -> Void
    var isEnabled: Bool = true

    func makeNSView(context: Context) -> NSView {
        let view = SwipeMonitorView()
        view.onSwipeToMixes = onSwipeToMixes
        view.onSwipeToSounds = onSwipeToSounds
        view.isEnabled = isEnabled
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? SwipeMonitorView else { return }
        view.onSwipeToMixes = onSwipeToMixes
        view.onSwipeToSounds = onSwipeToSounds
        view.isEnabled = isEnabled
    }

    private final class SwipeMonitorView: NSView {
        var onSwipeToMixes: () -> Void = {}
        var onSwipeToSounds: () -> Void = {}
        var isEnabled = true

        private var localMonitor: Any?
        private var accumulatedDeltaX: CGFloat = 0
        private var accumulatedAbsDeltaY: CGFloat = 0
        private var lastTriggerUptime: TimeInterval = 0

        private let swipeThreshold: CGFloat = 100
        private let horizontalDominanceRatio: CGFloat = 1.25
        private let swipeCooldown: TimeInterval = 0.35

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil {
                installLocalMonitorIfNeeded()
            } else {
                removeLocalMonitor()
            }
        }

        deinit {
            removeLocalMonitor()
        }

        private func installLocalMonitorIfNeeded() {
            guard localMonitor == nil else { return }
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) {
                [weak self] event in
                guard let self else { return event }
                return self.handleScrollEvent(event)
            }
        }

        private func removeLocalMonitor() {
            if let localMonitor {
                NSEvent.removeMonitor(localMonitor)
                self.localMonitor = nil
            }
            resetAccumulation()
        }

        private func handleScrollEvent(_ event: NSEvent) -> NSEvent {
            guard isEnabled else { return event }
            guard let window, event.window === window else { return event }
            guard event.hasPreciseScrollingDeltas else { return event }

            let pointInView = convert(event.locationInWindow, from: nil)
            guard bounds.contains(pointInView) else {
                resetAccumulationIfNeeded(for: event)
                return event
            }

            if event.phase == .began {
                resetAccumulation()
            }
            if event.phase == .ended || event.phase == .cancelled {
                resetAccumulation()
                return event
            }

            // Ignore inertia and text editing to avoid accidental section changes.
            if event.momentumPhase != [] {
                resetAccumulation()
                return event
            }
            if isTextInputFocused(in: window) {
                return event
            }

            accumulatedDeltaX += event.scrollingDeltaX
            accumulatedAbsDeltaY += abs(event.scrollingDeltaY)

            let absHorizontal = abs(accumulatedDeltaX)
            guard absHorizontal >= swipeThreshold else { return event }
            guard absHorizontal >= (accumulatedAbsDeltaY * horizontalDominanceRatio) else {
                if accumulatedAbsDeltaY >= swipeThreshold {
                    resetAccumulation()
                }
                return event
            }

            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastTriggerUptime >= swipeCooldown else { return event }
            lastTriggerUptime = now

            // Inverted direction by preference: positive deltaX -> Sounds, negative -> Mixes.
            if accumulatedDeltaX > 0 {
                onSwipeToSounds()
            } else {
                onSwipeToMixes()
            }
            resetAccumulation()
            return event
        }

        private func isTextInputFocused(in window: NSWindow) -> Bool {
            guard let responder = window.firstResponder else { return false }
            return responder is NSTextView
        }

        private func resetAccumulationIfNeeded(for event: NSEvent) {
            if event.phase == .ended || event.phase == .cancelled {
                resetAccumulation()
            }
        }

        private func resetAccumulation() {
            accumulatedDeltaX = 0
            accumulatedAbsDeltaY = 0
        }
    }
}

/// Native macOS search field using the standard Apple NSSearchField style.
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

struct SidebarResizeHandleView: View {
    let handleWidth: CGFloat
    let sidebarWidth: CGFloat
    let accessibilityLabel: String
    let accessibilityHint: String
    let onHoverChanged: (Bool) -> Void
    let onDisappearAction: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 1)
        }
        .frame(width: handleWidth)
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .offset(x: sidebarWidth - (handleWidth / 2))
        .onContinuousHover { phase in
            switch phase {
            case .active:
                onHoverChanged(true)
            case .ended:
                onHoverChanged(false)
            }
        }
        .onDisappear(perform: onDisappearAction)
        .highPriorityGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}
