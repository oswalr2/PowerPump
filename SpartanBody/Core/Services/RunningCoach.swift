import Foundation
import AVFoundation
import UIKit
import Combine

/// Speaks interval transitions, countdowns, and milestones during a running
/// program session, in the user's selected language. Also triggers vibration
/// cues. Both are independently controllable via Settings.
@MainActor
final class RunningCoach: ObservableObject {
    static let shared = RunningCoach()

    @Published var voiceEnabled: Bool { didSet { ud.set(voiceEnabled, forKey: "sb_voice_enabled") } }
    @Published var vibrationEnabled: Bool { didSet { ud.set(vibrationEnabled, forKey: "sb_vibration_enabled") } }

    private let synthesizer = AVSpeechSynthesizer()
    private let ud = UserDefaults.standard

    private init() {
        // Default both ON when the user has never opened settings.
        if ud.object(forKey: "sb_voice_enabled") == nil {
            voiceEnabled = true
            ud.set(true, forKey: "sb_voice_enabled")
        } else {
            voiceEnabled = ud.bool(forKey: "sb_voice_enabled")
        }
        if ud.object(forKey: "sb_vibration_enabled") == nil {
            vibrationEnabled = true
            ud.set(true, forKey: "sb_vibration_enabled")
        } else {
            vibrationEnabled = ud.bool(forKey: "sb_vibration_enabled")
        }
        configureAudioSession()
    }

    /// Configure the audio session so voice cues play even when the user
    /// locks their phone or switches to another app. We mix with other
    /// audio (Spotify, Apple Music) and duck them while speaking so the
    /// cue is heard clearly. Background playback requires `audio` in
    /// UIBackgroundModes — without that we still configure the session,
    /// the voice just stops if the screen locks.
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback,
                                     mode: .voicePrompt,
                                     options: [.mixWithOthers, .duckOthers])
            try session.setActive(true, options: [])
        } catch {
            // Falls back silently — the only consequence is that the voice
            // won't play in the background. We don't want a crash here.
        }
    }

    // MARK: - Voice

    /// Speaks an interval transition: "Walk for 2 minutes", "Now jog for 1 minute".
    func announceInterval(_ interval: ProgramInterval, isFirst: Bool) {
        guard voiceEnabled else { return }
        let action = PT(interval.kind.voiceKey)
        let durationPhrase = formatDurationPhrase(seconds: interval.duration)
        let lead = isFirst ? PT("voice.start") : PT("voice.now")
        let text = "\(lead) \(action) \(durationPhrase)"
        speak(text)
    }

    /// Spoken halfway through long intervals to keep the user motivated.
    func announceHalfway() {
        guard voiceEnabled else { return }
        speak(PT("voice.halfway"))
    }

    /// Spoken at the 3,2,1 countdown to the next interval.
    func announceCountdown(_ n: Int) {
        guard voiceEnabled else { return }
        speak("\(n)")
    }

    func announceFinish() {
        guard voiceEnabled else { return }
        speak(PT("voice.finish"))
    }

    func announcePause() {
        guard voiceEnabled else { return }
        speak(PT("voice.paused"))
    }

    func announceResume() {
        guard voiceEnabled else { return }
        speak(PT("voice.resumed"))
    }

    /// Speak an arbitrary line — used for AI-route turn-by-turn directions and
    /// stage announcements, which are already localized when passed in.
    func announce(_ text: String) {
        guard voiceEnabled, !text.isEmpty else { return }
        speak(text)
    }

    private func speak(_ text: String) {
        let code = LanguageManager.shared.selectedCode
        // AVSpeechSynthesisVoice prefers e.g. "es-ES" / "pt-BR".
        let localeID: String = {
            switch code {
            case "es": return "es-ES"
            case "fr": return "fr-FR"
            case "it": return "it-IT"
            case "pt-BR": return "pt-BR"
            default:   return "en-US"
            }
        }()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: localeID)
        utterance.rate = 0.5    // slightly slower than default; coachy
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0
        synthesizer.speak(utterance)
    }

    private func formatDurationPhrase(seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        // Use localized templates so the grammar adapts (1 minute / 1 minuto).
        if mins > 0 && secs == 0 {
            return String(format: PT("voice.duration.minutes"), mins)
        }
        if mins == 0 {
            return String(format: PT("voice.duration.seconds"), secs)
        }
        return String(format: PT("voice.duration.minutesSeconds"), mins, secs)
    }

    // MARK: - Haptics / Vibration

    private let feedback = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    /// Sharp double-tap at the start of an interval.
    func cueIntervalChange() {
        guard vibrationEnabled else { return }
        feedback.notificationOccurred(.success)
    }

    /// Soft tick during countdown 3,2,1.
    func cueCountdown() {
        guard vibrationEnabled else { return }
        selection.selectionChanged()
    }

    /// Long buzz at the end of the session.
    func cueFinish() {
        guard vibrationEnabled else { return }
        feedback.notificationOccurred(.success)
    }
}
