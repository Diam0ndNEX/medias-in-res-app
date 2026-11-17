import Foundation

enum ContentStore {
    /// Loads every bundled `lektion-XX.json`, sorted by lesson number.
    static func loadLessons() -> [Lesson] {
        let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        var lessons: [Lesson] = []
        for url in urls where url.lastPathComponent.hasPrefix("lektion-") {
            guard let data = try? Data(contentsOf: url) else { continue }
            do {
                var lesson = try JSONDecoder().decode(Lesson.self, from: data)
                let n = lesson.number
                lesson = Lesson(
                    number: lesson.number, title: lesson.title, unit: lesson.unit,
                    klasse: lesson.klasse,
                    vocab: lesson.vocab.map { var v = $0; v.lesson = n; return v },
                    vocabNote: lesson.vocabNote, grammar: lesson.grammar)
                lessons.append(lesson)
            } catch {
                print("Fehler beim Laden von \(url.lastPathComponent): \(error)")
            }
        }
        return lessons.sorted { $0.number < $1.number }
    }
}
