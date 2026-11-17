import Foundation
import Observation

enum ContentStore {
    /// Lädt alle mitgelieferten `lektion-XX.json`, sortiert nach Lektionsnummer.
    static func loadLessons() -> [Lesson] {
        let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        var lessons: [Lesson] = []
        for url in urls where url.lastPathComponent.hasPrefix("lektion-") {
            guard let data = try? Data(contentsOf: url) else { continue }
            do {
                var lesson = try JSONDecoder().decode(Lesson.self, from: data)
                let n = lesson.number
                lesson.vocab = lesson.vocab.map { item in
                    var v = item
                    v.lesson = n
                    return v
                }
                lessons.append(lesson)
            } catch {
                print("Fehler beim Laden von \(url.lastPathComponent): \(error)")
            }
        }
        return lessons.sorted { $0.number < $1.number }
    }
}

@Observable
final class AppData {
    let lessons: [Lesson]
    let allVocab: [VocabItem]

    init() {
        let l = ContentStore.loadLessons()
        lessons = l
        allVocab = l.flatMap { $0.vocab }
    }

    var numbers: [Int] { lessons.map { $0.number } }

    var units: [String] {
        var seen: [String] = []
        for l in lessons where !seen.contains(l.unit) { seen.append(l.unit) }
        return seen
    }

    func lessons(from: Int, to: Int) -> [Lesson] {
        lessons.filter { $0.number >= min(from, to) && $0.number <= max(from, to) }
    }

    func vocab(from: Int, to: Int) -> [VocabItem] {
        lessons(from: from, to: to).flatMap { $0.vocab }
    }
}
