import AVFoundation

/// Reads a Dutch word aloud with the device's own Dutch voice (SPEC.md → Hearing the Dutch word).
/// Works offline: iOS ships its Dutch voices. A new word stops the one being read.
@MainActor
final class DutchVoice {
    static let shared = DutchVoice()
    private let synthesizer = AVSpeechSynthesizer()

    func say(_ word: String) {
        // Spoken audio plays even with the ring switch on silent (you tapped for it), and
        // lowers music instead of stopping it.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(Self.utterance(for: word))
    }

    func stop() { synthesizer.stopSpeaking(at: .immediate) }

    static func utterance(for word: String) -> AVSpeechUtterance {
        let u = AVSpeechUtterance(string: word)
        u.voice = AVSpeechSynthesisVoice(language: "nl-NL")
        return u
    }
}
