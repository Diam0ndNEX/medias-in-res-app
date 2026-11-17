import Foundation

struct Lesson: Codable, Identifiable, Hashable {
    let number: Int
    let title: String
    let unit: String
    let klasse: Int
    let vocab: [VocabItem]
    let vocabNote: String?
    let grammar: [GrammarSection]

    var id: Int { number }

    static func == (a: Lesson, b: Lesson) -> Bool { a.number == b.number }
    func hash(into hasher: inout Hasher) { hasher.combine(number) }
}

struct VocabItem: Codable, Identifiable, Hashable {
    let la: String
    let forms: String
    let de: String
    let note: String
    var lesson: Int = 0

    var id: String { "\(lesson)|\(la)" }

    enum CodingKeys: String, CodingKey { case la, forms, de, note }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        la = try c.decode(String.self, forKey: .la)
        forms = try c.decodeIfPresent(String.self, forKey: .forms) ?? ""
        de = try c.decode(String.self, forKey: .de)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
}

struct GrammarSection: Codable, Identifiable, Hashable {
    let title: String
    let blocks: [Block]
    var id: String { title }
}

struct Block: Codable, Hashable, Identifiable {
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
