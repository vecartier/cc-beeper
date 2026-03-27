import Foundation
import AppKit

@MainActor
final class BuzzService {
    private var lastVibrateState: ClaudeState?
    private var reminderTimer: Timer?

    // MARK: - Cancellable shake state

    private var shakeWorkItems: [DispatchWorkItem] = []
    private(set) var isVibrating = false
    private var activeSound: NSSound?

    /// Called from ContentView.onReceive(monitor.$state) to handle vibration triggers.
    func handleStateChange(_ newState: ClaudeState, vibrationEnabled: Bool, soundEnabled: Bool) {
        // Vibration on done
        if vibrationEnabled && newState == .finished && lastVibrateState != newState {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.vibrate(soundEnabled: soundEnabled)
            }
        }

        // Needs permission: vibrate now + repeat every 15s
        if newState == .needsYou {
            if lastVibrateState != newState {
                if vibrationEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.vibrate(soundEnabled: soundEnabled)
                    }
                }
                reminderTimer?.invalidate()
                reminderTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        guard let self else { return }
                        self.vibrate(soundEnabled: soundEnabled)
                    }
                }
            }
        } else {
            reminderTimer?.invalidate()
            reminderTimer = nil
        }

        lastVibrateState = newState
    }

    func vibrate(soundEnabled: Bool) {
        if soundEnabled { playBeeps() }

        guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) else { return }
        let origin = window.frame.origin
        let shakes = 60
        let distance: CGFloat = 3
        let total = 3.0
        let interval = total / Double(shakes)

        // Cancel any in-progress vibration before starting new one
        cancelVibration(resetWindow: false)

        isVibrating = true

        for i in 0..<shakes {
            let item = DispatchWorkItem { [weak self] in
                guard let self, self.isVibrating else { return }
                // Skip shake frame if user is dragging (left mouse button held)
                guard NSEvent.pressedMouseButtons & 1 == 0 else { return }
                let dx: CGFloat = (i % 2 == 0) ? distance : -distance
                window.setFrameOrigin(NSPoint(x: origin.x + dx, y: origin.y))
            }
            shakeWorkItems.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i), execute: item)
        }

        // Reset to current position after all shakes complete (may have moved if user dragged)
        let resetItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isVibrating = false
            self.shakeWorkItems.removeAll()
            let current = window.frame.origin
            let snapped = NSPoint(x: round(current.x), y: round(current.y))
            window.setFrameOrigin(snapped)
        }
        shakeWorkItems.append(resetItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + total, execute: resetItem)
    }

    /// Immediately stops any in-progress vibration, cancels all pending shake work items,
    /// stops the current sound, and resets the window to its current position.
    /// Does NOT invalidate the reminderTimer — future reminders continue per design.
    func cancelVibration() {
        cancelVibration(resetWindow: true)
    }

    private func cancelVibration(resetWindow: Bool) {
        guard isVibrating || !shakeWorkItems.isEmpty else { return }

        for item in shakeWorkItems {
            item.cancel()
        }
        shakeWorkItems.removeAll()
        isVibrating = false

        activeSound?.stop()
        activeSound = nil

        if resetWindow,
           let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            let current = window.frame.origin
            window.setFrameOrigin(NSPoint(x: round(current.x), y: round(current.y)))
        }
    }

    private func playBeeps() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                let sound = NSSound(named: "Tink")
                sound?.play()
                if i == 0 { self.activeSound = sound }
            }
        }
    }
}
