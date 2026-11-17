import AVFoundation
import SwiftUI
import UIKit
import UserNotifications

// MARK: - Vorlesen

final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    override init() {
        super.init()
        synth.delegate = self
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Musik o. Ä. wieder auf normale Lautstärke bringen
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Latein wird mit italienischer Stimme vorgelesen (iOS hat keine lateinische Stimme).
    func speakLatin(_ text: String) { speak(text, language: "it-IT", rate: 0.42) }
    func speakGerman(_ text: String) { speak(text, language: "de-DE", rate: 0.5) }

    private func speak(_ text: String, language: String, rate: Float) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: language)
        u.rate = rate
        synth.speak(u)
    }
}

// MARK: - Haptik

enum Haptics {
    static var enabled: Bool { UserDefaults.standard.object(forKey: "hapticsOn") as? Bool ?? true }

    static func result(_ correct: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Antwortprüfung beim Eintippen

enum AnswerChecker {
    static func normalize(_ s: String) -> String {
        var t = s.lowercased()
        t = t.replacingOccurrences(of: "[0-9]\\)", with: " ", options: .regularExpression)
        for junk in ["er/sie/es ", "er/sie ", "(", ")", "!", "?", "„", "“", "\"", ".", "…", "(zu)", "sich "] {
            t = t.replacingOccurrences(of: junk, with: " ")
        }
        t = t.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespaces)
    }

    static func meanings(_ s: String) -> [String] {
        let parts = s.replacingOccurrences(of: " / ", with: ",")
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
        return parts.map(normalize).filter { !$0.isEmpty }
    }

    static func check(_ input: String, target: String, tolerant: Bool) -> Bool {
        let i = normalize(input)
        guard !i.isEmpty else { return false }
        let options = meanings(target) + [normalize(target)]
        for o in options {
            if o == i { return true }
            if tolerant {
                let allowed = o.count > 7 ? 2 : (o.count > 4 ? 1 : 0)
                if levenshtein(o, i) <= allowed { return true }
            }
        }
        return false
    }

    static func levenshtein(_ a: String, _ b: String) -> Int {
        let x = Array(a), y = Array(b)
        if x.isEmpty { return y.count }
        if y.isEmpty { return x.count }
        var prev = Array(0...y.count)
        var cur = Array(repeating: 0, count: y.count + 1)
        for i in 1...x.count {
            cur[0] = i
            for j in 1...y.count {
                let cost = x[i - 1] == y[j - 1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
            }
            prev = cur
        }
        return prev[y.count]
    }
}

// MARK: - Erinnerung

enum Reminder {
    static func schedule(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            center.removePendingNotificationRequests(withIdentifiers: ["daily"])
            let content = UNMutableNotificationContent()
            content.title = "Salve! 📜"
            content.body = "Zeit für deine tägliche Latein-Wiederholung."
            content.sound = .default
            var comps = DateComponents()
            comps.hour = hour
            comps.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            center.add(UNNotificationRequest(identifier: "daily", content: content, trigger: trigger))
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily"])
    }
}

// MARK: - Note (österreichisches Schema)

enum Grading {
    static func grade(correct: Int, total: Int) -> Int {
        guard total > 0 else { return 5 }
        let p = Double(correct) / Double(total)
        if p >= 0.875 { return 1 }
        if p >= 0.75 { return 2 }
        if p >= 0.625 { return 3 }
        if p >= 0.5 { return 4 }
        return 5
    }

    static func label(_ g: Int) -> String {
        ["", "Sehr gut", "Gut", "Befriedigend", "Genügend", "Nicht genügend"][max(1, min(5, g))]
    }
}

