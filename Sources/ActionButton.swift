import SwiftUI
import AppKit

// MARK: - Button Image Loader

func loadButtonImage(_ name: String) -> NSImage {
    if let path = Bundle.main.resourcePath,
       let img = NSImage(contentsOfFile: path + "/" + name) { return img }
    return NSImage()
}

// MARK: - Button sizes (@4x)

// Pill: 488×270 @4x → 122×68
private let pillW: CGFloat = 122
private let pillH: CGFloat = 68
// Individual: 312×270 @4x → 78×68
private let btnW: CGFloat = 78
private let btnH: CGFloat = 68

// MARK: - Accept / Deny Pill (dual tap zones)

struct AcceptDenyPill: View {
    let active: Bool
    let onAccept: () -> Void
    let onDeny: () -> Void

    @GestureState private var acceptPressed = false
    @GestureState private var denyPressed = false

    private var imageName: String {
        if !active { return "pill-disabled.png" }
        if acceptPressed { return "pill-check-pressed.png" }
        if denyPressed { return "pill-cross-pressed.png" }
        return "pill-normal.png"
    }

    var body: some View {
        ZStack {
            Image(nsImage: loadButtonImage(imageName))
                .resizable()
                .interpolation(.high)
                .allowsHitTesting(false)

            if active {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($acceptPressed) { _, state, _ in state = true }
                                .onEnded { _ in onAccept() }
                        )
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($denyPressed) { _, state, _ in state = true }
                                .onEnded { _ in onDeny() }
                        )
                }
            }
        }
        .frame(width: pillW, height: pillH)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Accept or Deny")
    }
}

// MARK: - Record Button

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Color.clear.frame(width: btnW, height: btnH)
        }
        .buttonStyle(ImageButtonStyle(
            normalImage: isRecording ? "record-recording.png" : "record-normal.png",
            pressedImage: isRecording ? "record-recording-pressed.png" : "record-pressed.png",
            width: btnW, height: btnH
        ))
        .accessibilityLabel(isRecording ? "Stop recording" : "Record")
    }
}

// MARK: - Terminal Button

struct TerminalButton: View {
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Color.clear.frame(width: btnW, height: btnH)
        }
        .buttonStyle(ImageButtonStyle(
            normalImage: enabled ? "terminal-normal.png" : "terminal-disabled.png",
            pressedImage: "terminal-pressed.png",
            width: btnW, height: btnH
        ))
        .disabled(!enabled)
        .accessibilityLabel("Go to terminal")
    }
}

// MARK: - Sound / Mute Button

struct SoundMuteButton: View {
    let voiceOver: Bool
    let action: () -> Void

    private var normalImage: String {
        voiceOver ? "sound-normal.png" : "mute-normal.png"
    }
    private var pressedImage: String {
        voiceOver ? "sound-pressed.png" : "mute-pressed.png"
    }

    var body: some View {
        Button(action: action) {
            Color.clear.frame(width: btnW, height: btnH)
        }
        .buttonStyle(ImageButtonStyle(
            normalImage: normalImage,
            pressedImage: pressedImage,
            width: btnW, height: btnH
        ))
        .accessibilityLabel(voiceOver ? "Mute" : "Unmute")
    }
}

// MARK: - Generic PNG Button Style

struct ImageButtonStyle: ButtonStyle {
    let normalImage: String
    let pressedImage: String
    let width: CGFloat
    let height: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        Image(nsImage: loadButtonImage(configuration.isPressed ? pressedImage : normalImage))
            .resizable()
            .interpolation(.high)
            .frame(width: width, height: height)
    }
}
