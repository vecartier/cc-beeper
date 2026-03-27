import SwiftUI
import Carbon.HIToolbox

struct SettingsHotkeysSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    var body: some View {
        Section("Global Hotkeys") {
            Text("All hotkeys use **⌥ Option** as the modifier. Click a key then press any letter to remap.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HotkeyRow(action: "Accept Permission", key: $monitor.hotkeyAccept)
            HotkeyRow(action: "Deny Permission", key: $monitor.hotkeyDeny)
            HotkeyRow(action: "Voice Record", key: $monitor.hotkeyVoice)
            HotkeyRow(action: "Go to Terminal", key: $monitor.hotkeyTerminal)
            HotkeyRow(action: "VoiceOver / Stop", key: $monitor.hotkeyMute)
        }
    }
}

// MARK: - Hotkey Row

struct HotkeyRow: View {
    let action: String
    @Binding var key: UInt16

    @State private var isRecording = false
    @State private var monitor: Any?

    private var keyLabel: String {
        "⌥ " + keyCodeToString(key)
    }

    var body: some View {
        HStack {
            Text(action)
            Spacer()
            Button(isRecording ? "Press a key…" : keyLabel) {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
            .buttonStyle(.bordered)
            .foregroundStyle(isRecording ? .orange : .primary)
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let code = event.keyCode
            if code == 53 { // Escape — cancel
                stopRecording()
                return nil
            }
            // Only accept letter keys (0-50 range covers A-Z on US keyboard)
            if code <= 50, keyCodeToString(code) != "?" {
                key = code
                stopRecording()
                return nil // consume the event
            }
            return event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}

// MARK: - Key Code Utilities

func keyCodeToString(_ code: UInt16) -> String {
    switch Int(code) {
    case kVK_ANSI_A: return "A"
    case kVK_ANSI_S: return "S"
    case kVK_ANSI_D: return "D"
    case kVK_ANSI_F: return "F"
    case kVK_ANSI_G: return "G"
    case kVK_ANSI_H: return "H"
    case kVK_ANSI_J: return "J"
    case kVK_ANSI_K: return "K"
    case kVK_ANSI_L: return "L"
    case kVK_ANSI_Q: return "Q"
    case kVK_ANSI_W: return "W"
    case kVK_ANSI_E: return "E"
    case kVK_ANSI_R: return "R"
    case kVK_ANSI_T: return "T"
    case kVK_ANSI_Y: return "Y"
    case kVK_ANSI_U: return "U"
    case kVK_ANSI_I: return "I"
    case kVK_ANSI_O: return "O"
    case kVK_ANSI_P: return "P"
    case kVK_ANSI_Z: return "Z"
    case kVK_ANSI_X: return "X"
    case kVK_ANSI_C: return "C"
    case kVK_ANSI_V: return "V"
    case kVK_ANSI_B: return "B"
    case kVK_ANSI_N: return "N"
    case kVK_ANSI_M: return "M"
    default: return "?"
    }
}
