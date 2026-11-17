import Foundation

struct Lesson: Decodable, Identifiable, Hashable {
    let number: Int
    let title: String
    let unit: String
    let klasse: Int
    var vocab: [VocabItem]
    let vocabNote: String?
    let grammar: [GrammarSection]

    var id: Int { number }

    static func == (a: Lesson, b: Lesson) -> Bool { a.number == b.number }
    func hash(into hasher: inout Hasher) { hasher.combine(number) }
}

struct VocabItem: Decodable, Identifiable, Hashable {
    let la: String
    let forms: String
    let de: String
    let note: String
    let pos: String
    var lesson: Int = 0

    var id: String { "\(lesson)|\(la)" }

    enum CodingKeys: String, CodingKey { case la, forms, de, note, pos }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        la = try c.decode(String.self, forKey: .la)
        forms = try c.decodeIfPresent(String.self, forKey: .forms) ?? ""
        de = try c.decode(String.self, forKey: .de)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        pos = try c.decodeIfPresent(String.self, forKey: .pos) ?? "Sonstiges"
    }

    static func == (a: VocabItem, b: VocabItem) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Lateinisches Stichwort ohne Klammerzusätze und Geschlechtsangabe.
    var headLa: String {
        var s = la
        if let r = s.range(of: " (") { s = String(s[..<r.lowerBound]) }
        for suffix in [" m.", " f.", " n."] where s.hasSuffix(suffix) {
            s = String(s.dropLast(suffix.count))
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// Text zum Vorlesen (ohne Schrägstriche und Zusätze).
    var speakable: String {
        headLa.replacingOccurrences(of: "/", with: " ").replacingOccurrences(of: "–", with: " ")
    }

    var hasStemForms: Bool {
        pos == "Verb" && forms.contains(",")
    }
}

struct GrammarSection: Decodable, Identifiable, Hashable {
    let title: String
    let blocks: [Block]
    var id: String { title }
}

struct Block: Decodable, Hashable, Identifiable {
    let type: String          // text, list, tip, note, table
    let text: String?
    let items: [String]?
    let headers: [String]?
    let rows: [[String]]?

    var id: String {
        var parts: [String] = [type]
        parts.append(text ?? "")
        parts.append((items ?? []).joined())
        let cells: [String] = (rows ?? []).flatMap { $0 }
        parts.append(cells.joined())
        return parts.joined(separator: "|")
    }
}

// MARK: - Vokabel des Tages

enum DailyWord {
    static func pick(from items: [VocabItem], date: Date = Date()) -> VocabItem? {
        guard !items.isEmpty else { return nil }
        let day = Int(date.timeIntervalSince1970 / 86_400)
        return items[(day &* 7919) % items.count]
    }
}
