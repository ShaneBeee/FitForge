import Foundation
import AVFoundation

/// Speaks short workout prompts ("Rest's up. Set 2 of 3.") and ducks any music while talking.
final class VoiceCoach: NSObject, AVSpeechSynthesizerDelegate {
    /// UserDefaults key for the voice picked in Profile → Coach voice.
    static let voiceDefaultsKey = "coachVoiceIdentifier"

    private let synthesizer = AVSpeechSynthesizer()
    var isEnabled = true

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Voices

    /// The voice the user picked, or the best-quality voice installed for their language.
    static var selectedVoice: AVSpeechSynthesisVoice? {
        if let identifier = UserDefaults.standard.string(forKey: voiceDefaultsKey),
           !identifier.isEmpty,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        return bestAvailableVoice()
    }

    /// Installed voices for the user's language, best quality first. Novelty voices are left out.
    static var availableVoices: [AVSpeechSynthesisVoice] {
        let languagePrefix = String(AVSpeechSynthesisVoice.currentLanguageCode().prefix(2))
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(languagePrefix) && !$0.voiceTraits.contains(.isNoveltyVoice) }
            .sorted { score($0) > score($1) || (score($0) == score($1) && $0.name < $1.name) }
    }

    static func bestAvailableVoice() -> AVSpeechSynthesisVoice? {
        availableVoices.first
    }

    /// Premium beats Enhanced beats standard; the user's exact region gets a small bonus.
    private static func score(_ voice: AVSpeechSynthesisVoice) -> Int {
        let regionBonus = voice.language == AVSpeechSynthesisVoice.currentLanguageCode() ? 1 : 0
        return voice.quality.rawValue * 10 + regionBonus
    }

    // MARK: - Speaking

    func speak(_ text: String, voice: AVSpeechSynthesisVoice? = nil) {
        guard isEnabled else { return }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
        try? session.setActive(true)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(attributedString: Self.withPronunciations(text))
        utterance.voice = voice ?? Self.selectedVoice
        // A short pause first gives the audio system (especially Bluetooth headphones)
        // time to wake up, so the start of the first word isn't clipped.
        utterance.preUtteranceDelay = 0.25
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        releaseAudio()
    }

    /// Words the speech engine tends to misread, with how they should sound (IPA).
    /// e.g. without this, "reps" gets read as "representatives".
    private static let pronunciations: [String: String] = [
        "reps": "ɹˈɛps",
        "rep": "ɹˈɛp"
    ]

    private static func withPronunciations(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text)
        let nsText = text as NSString
        for (word, ipa) in pronunciations {
            // Whole words only, any capitalisation.
            guard let regex = try? NSRegularExpression(pattern: "\\b\(word)\\b", options: .caseInsensitive) else { continue }
            for match in regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {
                result.addAttribute(
                    NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute),
                    value: ipa,
                    range: match.range
                )
            }
        }
        return result
    }

    private func releaseAudio() {
        guard !synthesizer.isSpeaking else { return }
        // Un-duck the user's music once we're done talking.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.releaseAudio() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.releaseAudio() }
    }
}

extension AVSpeechSynthesisVoice {
    /// "Premium", "Enhanced" or "Standard"
    var qualityLabel: String {
        switch quality {
        case .premium: "Premium"
        case .enhanced: "Enhanced"
        default: "Standard"
        }
    }

    /// e.g. "English (Canada)"
    var languageLabel: String {
        Locale.current.localizedString(forIdentifier: language) ?? language
    }
}
