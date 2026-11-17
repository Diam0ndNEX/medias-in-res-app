import Foundation

enum Direction: String, CaseIterable, Identifiable {
    case laDe, deLa, mixed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .laDe: return "Lat → Dt"
        case .deLa: return "Dt → Lat"
        case .mixed: return "Gemischt"
        }
    }
    func resolve() -> Direction {
        self == .mixed ? (Bool.random() ? .laDe : .deLa) : self
    }
}

struct Question: Identifiable {
    let id = UUID()
    var prompt: String
    var hint: String = ""
    var options: [String]
    var correct: Int
    var item: VocabItem? = nil
    var explanation: String = ""
    var speakLatin: String? = nil
    var category: String = ""
}

/// Einstellungen für eine Übungsrunde.
struct PracticeConfig: Hashable {
    var from: Int = 1
    var to: Int = 1
    var pos: String = "Alle"
    var direction: Direction = .laDe
    var count: Int = 20          // 0 = alle

    var rangeLabel: String { from == to ? "Lektion \(from)" : "Lektion \(min(from, to))–\(max(from, to))" }

    func items(_ app: AppData) -> [VocabItem] {
        let all = app.vocab(from: from, to: to)
        return pos == "Alle" ? all : all.filter { $0.pos == pos }
    }

    func limited<T>(_ list: [T]) -> [T] {
        count == 0 ? list : Array(list.prefix(count))
    }
}

enum QuestionFactory {
    static let posOptions = ["Alle", "Nomen", "Verb", "Adjektiv", "Adverb", "Präposition", "Sonstiges"]

    // MARK: Ablenker

    static func distractors(for item: VocabItem, pool: [VocabItem], fallback: [VocabItem],
                            count: Int, key: (VocabItem) -> String) -> [String] {
        let correctKey = key(item)
        var result: [String] = []
        func add(from list: [VocabItem]) {
            for v in list.shuffled() {
                let k = key(v)
                if result.count >= count { return }
                if k != correctKey && !result.contains(k) && !k.isEmpty { result.append(k) }
            }
        }
        add(from: pool.filter { $0.pos == item.pos })
        add(from: pool)
        add(from: fallback.filter { $0.pos == item.pos })
        add(from: fallback)
        return result
    }

    private static func makeMC(prompt: String, hint: String, correct: String, wrong: [String]) -> ([String], Int) {
        var opts = wrong + [correct]
        opts.shuffle()
        return (opts, opts.firstIndex(of: correct) ?? 0)
    }

    // MARK: Vokabel-Fragen

    static func vocabMC(_ item: VocabItem, pool: [VocabItem], all: [VocabItem], direction: Direction) -> Question {
        let dir = direction.resolve()
        if dir == .laDe {
            let wrong = distractors(for: item, pool: pool, fallback: all, count: 3) { $0.de }
            let (opts, idx) = makeMC(prompt: item.la, hint: item.forms, correct: item.de, wrong: wrong)
            return Question(prompt: item.la, hint: item.forms, options: opts, correct: idx, item: item,
                            explanation: item.note, speakLatin: item.speakable, category: "Vokabel")
        } else {
            let wrong = distractors(for: item, pool: pool, fallback: all, count: 3) { $0.la }
            let (opts, idx) = makeMC(prompt: item.de, hint: "", correct: item.la, wrong: wrong)
            let expl = [item.forms, item.note].filter { !$0.isEmpty }.joined(separator: " · ")
            return Question(prompt: item.de, hint: item.pos == "Sonstiges" ? "" : item.pos, options: opts, correct: idx, item: item,
                            explanation: expl, category: "Vokabel")
        }
    }

    static func trueFalse(_ item: VocabItem, pool: [VocabItem], all: [VocabItem]) -> Question {
        let truth = Bool.random()
        let shown = truth ? item.de : (distractors(for: item, pool: pool, fallback: all, count: 1) { $0.de }.first ?? item.de)
        let isTrue = shown == item.de
        return Question(prompt: item.la, hint: "= \(shown)?", options: ["Richtig", "Falsch"],
                        correct: isTrue ? 0 : 1, item: item,
                        explanation: isTrue ? "" : "Richtig wäre: \(item.de)",
                        speakLatin: item.speakable, category: "Richtig/Falsch")
    }

    static func listening(_ item: VocabItem, pool: [VocabItem], all: [VocabItem]) -> Question {
        var q = vocabMC(item, pool: pool, all: all, direction: .laDe)
        q.hint = "Hör genau hin 🎧"
        q.explanation = "\(item.la) – \(item.de)"
        q.category = "Hören"
        q.prompt = "🔊"
        return q
    }

    /// Zerlegt z. B. "capio M, cepi, captum" in (1. Person, Perfekt, PPP); kürzt "-avi, -atum" aus.
    static func stemParts(_ item: VocabItem) -> (first: String, perfect: String, ppp: String)? {
        guard item.hasStemForms else { return nil }
        let parts = item.forms.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 2 else { return nil }
        var firstWord = parts[0].components(separatedBy: " ").first ?? ""
        var rest = Array(parts.dropFirst())
        if !firstWord.hasSuffix("o") {
            // Lektion 1–4: Verb steht in der 3. Person, zweite Spalte beginnt direkt mit dem Perfekt
            firstWord = item.la.components(separatedBy: CharacterSet(charactersIn: " ,")).first ?? ""
            rest = parts
        }
        let base: String
        if firstWord.hasSuffix("o") {
            base = String(firstWord.dropLast())               // laudo → laud
        } else if firstWord.hasSuffix("t") && firstWord.count > 3 {
            base = String(firstWord.dropLast(2))              // laudat → laud
        } else {
            return nil
        }
        func expand(_ p: String) -> String? {
            if p == "–" || p.isEmpty { return p }
            if p.hasPrefix("-") {
                switch p {
                case "-avi": return base + "avi"
                case "-atum": return base + "atum"
                case "-ui": return (base.hasSuffix("e") ? String(base.dropLast()) : base) + "ui"
                case "-itum": return (base.hasSuffix("e") || base.hasSuffix("i") ? String(base.dropLast()) : base) + "itum"
                case "-ivi": return (base.hasSuffix("i") ? String(base.dropLast()) : base) + "ivi"
                default: return nil
                }
            }
            return p
        }
        // unregelmäßige Verba führen zusätzlich die 2. Person an (z. B. "fero, fers, tuli, latum")
        let pIdx = rest.count >= 3 ? 1 : 0
        guard pIdx < rest.count, let perf = expand(rest[pIdx]), perf.count > 1, !perf.contains(" ") else { return nil }
        let ppp = rest.count > pIdx + 1 ? (expand(rest[pIdx + 1]) ?? "") : ""
        return (firstWord, perf, ppp)
    }

    static func stemForms(_ item: VocabItem, pool: [VocabItem], all: [VocabItem]) -> Question? {
        guard let p = stemParts(item) else { return nil }
        if Bool.random() {
            // Perfekt bilden: echte Form gegen regelmäßig "falsch gebildete" Formen
            var stem = p.first
            if stem.hasSuffix("t") {
                stem = String(stem.dropLast(2))
            } else {
                for end in ["io", "eo", "o"] where stem.hasSuffix(end) { stem = String(stem.dropLast(end.count)); break }
            }
            let fakes = [stem + "avi", stem + "ivi", stem + "ui", stem + "si", stem + "xi", stem + "i", stem + "evi"]
                .filter { $0 != p.perfect }
            var opts = Array(Set(fakes)).shuffled().prefix(3).map { $0 } + [p.perfect]
            opts.shuffle()
            return Question(prompt: item.la, hint: "Wie lautet das Perfekt? (\(p.first) = \(item.de))", options: opts,
                            correct: opts.firstIndex(of: p.perfect) ?? 0, item: item,
                            explanation: "\(item.la): \(item.forms)", speakLatin: item.speakable,
                            category: "Stammformen")
        } else {
            // Perfektform erkennen: Zu welchem Verb gehört …?
            let shown = [p.perfect, p.ppp].filter { !$0.isEmpty && $0 != "–" }.joined(separator: ", ")
            let others = pool.filter { $0.hasStemForms } + all.filter { $0.hasStemForms }
            let wrong = distractors(for: item, pool: others, fallback: all, count: 3) { $0.la }
            var opts = wrong + [item.la]
            opts.shuffle()
            return Question(prompt: shown, hint: "Zu welchem Verb gehört diese Form?", options: opts,
                            correct: opts.firstIndex(of: item.la) ?? 0, item: item,
                            explanation: "\(item.la) = \(item.de) · \(item.forms)",
                            category: "Stammformen")
        }
    }

    /// Fremdwort-Detektiv: aus dem Hinweis (z. B. „vgl. Laudatio“) das lateinische Wort erraten.
    static func foreignWord(_ item: VocabItem, pool: [VocabItem], all: [VocabItem]) -> Question? {
        let markers = ["vgl.", "engl.", "frz.", "ital.", "span."]
        guard item.note.count > 6, markers.contains(where: { item.note.contains($0) }) else { return nil }
        var clue = item.note
        // das Lösungswort selbst (als ganzes Wort) aus dem Hinweis entfernen
        for token in item.headLa.components(separatedBy: CharacterSet(charactersIn: " /,")) where token.count > 2 {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: token) + "\\b"
            clue = clue.replacingOccurrences(of: pattern, with: "…", options: [.regularExpression, .caseInsensitive])
        }
        let wrong = distractors(for: item, pool: pool, fallback: all, count: 3) { $0.la }
        let (opts, idx) = makeMC(prompt: clue, hint: "", correct: item.la, wrong: wrong)
        return Question(prompt: clue, hint: "Welches lateinische Wort steckt dahinter?", options: opts,
                        correct: idx, item: item, explanation: "\(item.la) = \(item.de) · \(item.note)",
                        category: "Fremdwort-Detektiv")
    }

    // MARK: Formen aus den Grammatik-Tabellen

    struct FormCell { let form: String; let label: String; let context: String }

    static func formCells(_ lessons: [Lesson]) -> [[FormCell]] {
        var tables: [[FormCell]] = []
        for lesson in lessons {
            for section in lesson.grammar {
                for block in section.blocks where block.type == "table" {
                    let headers = block.headers ?? []
                    var cells: [FormCell] = []
                    for row in block.rows ?? [] {
                        guard let rowLabel = row.first?.trimmingCharacters(in: .whitespaces),
                              !rowLabel.isEmpty, row.count > 1 else { continue }
                        for col in 1..<row.count {
                            let form = cleanForm(row[col])
                            guard isUsableForm(form) else { continue }
                            let header = col < headers.count ? headers[col].trimmingCharacters(in: .whitespaces) : ""
                            let label = header.isEmpty ? rowLabel : "\(rowLabel) · \(header)"
                            cells.append(FormCell(form: form, label: label,
                                                  context: "Lektion \(lesson.number): \(section.title)"))
                        }
                    }
                    let labels = Set(cells.map { $0.label })
                    let forms = Set(cells.map { $0.form })
                    if labels.count >= 4 && forms.count >= 4 { tables.append(cells) }
                }
            }
        }
        return tables
    }

    static func cleanForm(_ s: String) -> String {
        var t = s
        if let r = t.range(of: "„") { t = String(t[..<r.lowerBound]) }
        t = t.replacingOccurrences(of: "!", with: "")
        return t.trimmingCharacters(in: .whitespaces)
    }

    static func isUsableForm(_ f: String) -> Bool {
        guard !f.isEmpty, f.count <= 24, f != "–" else { return false }
        for bad in [":", ";", "(", "…", "„", "=", "→"] where f.contains(bad) { return false }
        return f.split(separator: " ").count <= 3
    }

    /// „Bestimme diese Form“
    static func identifyForms(_ lessons: [Lesson]) -> [Question] {
        var out: [Question] = []
        for table in formCells(lessons) {
            for cell in table {
                let correctLabels = Set(table.filter { $0.form == cell.form }.map { $0.label })
                let others = Array(Set(table.map { $0.label }).subtracting(correctLabels)).shuffled().prefix(3)
                guard others.count == 3 else { continue }
                var opts = Array(others) + [cell.label]
                opts.shuffle()
                out.append(Question(prompt: cell.form, hint: "Bestimme die Form", options: opts,
                                    correct: opts.firstIndex(of: cell.label) ?? 0,
                                    explanation: cell.context, category: "Formen bestimmen"))
            }
        }
        return out
    }

    /// „Bilde diese Form“
    static func buildForms(_ lessons: [Lesson]) -> [Question] {
        var out: [Question] = []
        for table in formCells(lessons) {
            for cell in table {
                let sameLabel = Set(table.filter { $0.label == cell.label }.map { $0.form })
                let others = Array(Set(table.map { $0.form }).subtracting(sameLabel)).shuffled().prefix(3)
                guard others.count == 3 else { continue }
                var opts = Array(others) + [cell.form]
                opts.shuffle()
                out.append(Question(prompt: cell.label, hint: cell.context, options: opts,
                                    correct: opts.firstIndex(of: cell.form) ?? 0,
                                    explanation: "\(cell.label): \(cell.form)", category: "Formen bilden"))
            }
        }
        return out
    }

    // MARK: Schularbeit

    static func exam(config: PracticeConfig, app: AppData, total: Int) -> [Question] {
        let pool = config.items(app)
        guard !pool.isEmpty else { return [] }
        let lessons = app.lessons(from: config.from, to: config.to)
        var qs: [Question] = []
        let vocabCount = Int(Double(total) * 0.5)
        let tfCount = Int(Double(total) * 0.15)
        let stemCount = Int(Double(total) * 0.1)
        for item in pool.shuffled().prefix(vocabCount) {
            qs.append(vocabMC(item, pool: pool, all: app.allVocab, direction: .mixed))
        }
        for item in pool.shuffled().prefix(tfCount) {
            qs.append(trueFalse(item, pool: pool, all: app.allVocab))
        }
        let stems = pool.filter { $0.hasStemForms }.shuffled().prefix(stemCount)
        qs += stems.compactMap { stemForms($0, pool: pool, all: app.allVocab) }
        let rest = total - qs.count
        let forms = (identifyForms(lessons) + buildForms(lessons)).shuffled()
        qs += forms.prefix(rest)
        if qs.count < total {
            for item in pool.shuffled().prefix(total - qs.count) {
                qs.append(vocabMC(item, pool: pool, all: app.allVocab, direction: .mixed))
            }
        }
        return qs.shuffled()
    }
}
