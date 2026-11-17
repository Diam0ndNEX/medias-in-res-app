import Foundation
import Observation

struct ItemStats: Codable {
    var box: Int = 0          // 0 = noch nie geübt, 1…5 Leitner-Box
    var right: Int = 0
    var wrong: Int = 0
    var lastSeen: Date? = nil
    var lastWrong: Date? = nil
}

struct TestResult: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var range: String
    var correct: Int
    var total: Int
    var grade: Int
}

struct ProgressData: Codable {
    var items: [String: ItemStats] = [:]
    var days: [String: Int] = [:]          // "yyyy-MM-dd" → beantwortete Fragen
    var tests: [TestResult] = []
    var highscores: [String: Int] = [:]
}

/// Lernfortschritt, lokal in UserDefaults gespeichert.
@Observable
final class ProgressStore {
    private(set) var data = ProgressData()
    private let key = "progress.v2"

    /// Wiederholungsabstände pro Box in Tagen.
    static let intervals: [Int: Double] = [1: 0, 2: 1, 3: 3, 4: 7, 5: 14]

    init() {
        if let raw = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(ProgressData.self, from: raw) {
            data = decoded
        } else if let old = UserDefaults.standard.data(forKey: "leitnerBoxes.v1"),
                  let boxes = try? JSONDecoder().decode([String: Int].self, from: old) {
            for (k, b) in boxes { data.items[k] = ItemStats(box: b) }
        }
    }

    // MARK: Vokabeln

    func stats(for item: VocabItem) -> ItemStats { data.items[item.id] ?? ItemStats() }
    func box(for item: VocabItem) -> Int { stats(for: item).box }

    func record(_ item: VocabItem, knew: Bool) {
        var s = stats(for: item)
        s.lastSeen = Date()
        if knew {
            s.right += 1
            s.box = min(max(s.box, 1) + 1, 5)
        } else {
            s.wrong += 1
            s.box = 1
            s.lastWrong = Date()
        }
        data.items[item.id] = s
        countActivity()
    }

    /// Zählt eine beantwortete Frage, die keiner Vokabel zugeordnet ist (z. B. Formen).
    func countActivity() {
        data.days[Self.dayKey(Date()), default: 0] += 1
        save()
    }

    func isDue(_ item: VocabItem, now: Date = Date()) -> Bool {
        let s = stats(for: item)
        guard s.box > 0, let last = s.lastSeen else { return false }
        let days = Self.intervals[s.box] ?? 1
        return now.timeIntervalSince(last) >= days * 86_400 - 3_600
    }

    func dueItems(in items: [VocabItem], newLimit: Int = 10, maxTotal: Int = 40) -> [VocabItem] {
        let due = items.filter { isDue($0) }.shuffled()
        let fresh = items.filter { box(for: $0) == 0 }.prefix(newLimit)
        return Array((due + fresh).prefix(maxTotal))
    }

    func mistakes(in items: [VocabItem]) -> [VocabItem] {
        items.filter {
            let s = stats(for: $0)
            return s.wrong > 0 && s.box <= 2
        }
    }

    func mastered(in items: [VocabItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        return Double(items.filter { box(for: $0) >= 4 }.count) / Double(items.count)
    }

    func seen(in items: [VocabItem]) -> Int { items.filter { box(for: $0) > 0 }.count }

    func hardest(in items: [VocabItem], limit: Int = 20) -> [VocabItem] {
        let candidates = items.filter { stats(for: $0).wrong > 0 }
        let sorted = candidates.sorted { difficulty($0) > difficulty($1) }
        return Array(sorted.prefix(limit))
    }

    private func difficulty(_ item: VocabItem) -> Int {
        let s = stats(for: item)
        return s.wrong * 3 - s.right
    }

    // MARK: Tage / Streak

    var todayCount: Int { data.days[Self.dayKey(Date())] ?? 0 }
    var totalAnswered: Int { data.days.values.reduce(0, +) }

    var streak: Int {
        var count = 0
        var day = Date()
        if data.days[Self.dayKey(day)] == nil {
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while data.days[Self.dayKey(day)] != nil {
            count += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return count
    }

    func lastDays(_ n: Int) -> [(String, Int)] {
        (0..<n).reversed().map { offset in
            let d = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let f = DateFormatter()
            f.dateFormat = "EE"
            f.locale = Locale(identifier: "de_AT")
            return (f.string(from: d), data.days[Self.dayKey(d)] ?? 0)
        }
    }

    // MARK: Tests / Highscores

    func addTest(_ r: TestResult) {
        data.tests.insert(r, at: 0)
        save()
    }

    func highscore(_ key: String) -> Int { data.highscores[key] ?? 0 }

    @discardableResult
    func submitHighscore(_ key: String, _ value: Int) -> Bool {
        if value > highscore(key) {
            data.highscores[key] = value
            save()
            return true
        }
        return false
    }

    // MARK: Backup

    func exportFile() -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MediasInRes-Fortschritt.json")
        let enc = JSONEncoder()
        enc.outputFormatting = .prettyPrinted
        enc.dateEncodingStrategy = .iso8601
        guard let raw = try? enc.encode(data) else { return nil }
        try? raw.write(to: url)
        return url
    }

    func importFile(_ url: URL) -> Bool {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        guard let raw = try? Data(contentsOf: url) else { return false }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        guard let decoded = try? dec.decode(ProgressData.self, from: raw) else { return false }
        data = decoded
        save()
        return true
    }

    func resetAll() {
        data = ProgressData()
        save()
    }

    // MARK: intern

    static func dayKey(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: d)
    }

    private func save() {
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: key)
        }
    }
}
