import Foundation
import Observation

/// Leitner-Fortschritt: pro Vokabel eine Box 1…5 (nur lokal, UserDefaults).
@Observable
final class ProgressStore {
    private(set) var boxes: [String: Int] = [:]
    private let key = "leitnerBoxes.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            boxes = decoded
        }
    }

    func box(for item: VocabItem) -> Int { boxes[item.id] ?? 0 }   // 0 = noch nie geübt

    func record(_ item: VocabItem, knew: Bool) {
        let current = boxes[item.id] ?? 0
        boxes[item.id] = knew ? min(max(current, 1) + 1, 5) : 1
        save()
    }

    func resetAll() {
        boxes = [:]
        save()
    }

    /// Anteil der Vokabeln in Box 4–5 ("sitzt").
    func mastered(in items: [VocabItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        return Double(items.filter { box(for: $0) >= 4 }.count) / Double(items.count)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(boxes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
