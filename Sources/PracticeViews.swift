import SwiftUI

enum PracticeMode: String, CaseIterable, Identifiable {
    case daily, flashcards, multipleChoice, trueFalse, matching, listening, blitz, typing
    case stemForms, foreignWords, mistakes
    case formsIdentify, formsBuild, tables
    case exam

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Tägliche Wiederholung"
        case .flashcards: return "Karteikarten"
        case .multipleChoice: return "Multiple Choice"
        case .trueFalse: return "Richtig oder falsch?"
        case .matching: return "Zuordnen"
        case .listening: return "Hör-Modus"
        case .blitz: return "Blitzrunde (60 s)"
        case .typing: return "Eintippen"
        case .stemForms: return "Stammformen"
        case .foreignWords: return "Fremdwort-Detektiv"
        case .mistakes: return "Fehlerkiste"
        case .formsIdentify: return "Formen bestimmen"
        case .formsBuild: return "Formen bilden"
        case .tables: return "Tabellen lernen"
        case .exam: return "Schularbeit-Modus"
        }
    }

    var subtitle: String {
        switch self {
        case .daily: return "Fällige Karten aus allen Lektionen"
        case .flashcards: return "Umdrehen und selbst bewerten, wischen"
        case .multipleChoice: return "4 Antworten zur Auswahl"
        case .trueFalse: return "Stimmt die Übersetzung?"
        case .matching: return "Latein und Deutsch paarweise verbinden"
        case .listening: return "Wort anhören, Bedeutung wählen"
        case .blitz: return "So viele wie möglich in 60 Sekunden"
        case .typing: return "Übersetzung selbst eintippen"
        case .stemForms: return "Perfekt- und PPP-Formen der Verben"
        case .foreignWords: return "Welches Wort steckt im Fremdwort?"
        case .mistakes: return "Nur Wörter, die du falsch hattest"
        case .formsIdentify: return "Fall, Zahl, Person … bestimmen"
        case .formsBuild: return "Die richtige Form auswählen"
        case .tables: return "Deklinations- und Konjugationstabellen aufdecken"
        case .exam: return "Gemischter Test mit Note 1–5"
        }
    }

    var icon: String {
        switch self {
        case .daily: return "calendar.badge.clock"
        case .flashcards: return "rectangle.on.rectangle.angled"
        case .multipleChoice: return "list.bullet.circle"
        case .trueFalse: return "checkmark.circle.badge.xmark"
        case .matching: return "square.grid.2x2"
        case .listening: return "headphones"
        case .blitz: return "bolt.fill"
        case .typing: return "keyboard"
        case .stemForms: return "text.word.spacing"
        case .foreignWords: return "magnifyingglass"
        case .mistakes: return "exclamationmark.triangle"
        case .formsIdentify: return "tablecells"
        case .formsBuild: return "hammer"
        case .tables: return "eye.slash"
        case .exam: return "graduationcap"
        }
    }

    var color: Color {
        switch self {
        case .daily, .mistakes: return .orange
        case .flashcards, .multipleChoice, .trueFalse, .matching, .typing: return .blue
        case .listening, .blitz: return .purple
        case .stemForms, .foreignWords: return .teal
        case .formsIdentify, .formsBuild, .tables: return .indigo
        case .exam: return .red
        }
    }
}

// MARK: - Üben-Tab

struct PracticeHubView: View {
    @Environment(AppData.self) private var app
    @Environment(ProgressStore.self) private var progress
    @AppStorage("typingEnabled") private var typingEnabled = false
    @AppStorage("practiceFrom") private var from = 1
    @AppStorage("practiceTo") private var to = 5
    @AppStorage("practicePos") private var pos = "Alle"
    @AppStorage("practiceDir") private var dirRaw = Direction.laDe.rawValue
    @AppStorage("practiceCount") private var count = 20

    private var config: PracticeConfig {
        PracticeConfig(from: from, to: to, pos: pos, direction: Direction(rawValue: dirRaw) ?? .laDe, count: count)
    }

    var body: some View {
        List {
            Section {
                rangePicker
                Picker("Wortart", selection: $pos) {
                    ForEach(QuestionFactory.posOptions, id: \.self) { Text($0).tag($0) }
                }
                Picker("Richtung", selection: $dirRaw) {
                    ForEach(Direction.allCases) { Text($0.label).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                Picker("Anzahl", selection: $count) {
                    Text("10").tag(10)
                    Text("20").tag(20)
                    Text("40").tag(40)
                    Text("Alle").tag(0)
                }
                .pickerStyle(.segmented)
                Text("\(config.items(app).count) Vokabeln in \(config.rangeLabel)")
                    .font(.caption).foregroundStyle(.secondary)
            } header: {
                Text("Bereich")
            }

            Section("Heute") {
                modeLink(.daily)
                modeLink(.mistakes)
            }
            Section("Vokabeln") {
                modeLink(.flashcards)
                modeLink(.multipleChoice)
                modeLink(.trueFalse)
                modeLink(.matching)
                modeLink(.listening)
                modeLink(.blitz)
                if typingEnabled { modeLink(.typing) }
                modeLink(.stemForms)
                modeLink(.foreignWords)
            }
            Section("Grammatik") {
                modeLink(.formsIdentify)
                modeLink(.formsBuild)
                modeLink(.tables)
            }
            Section("Test") {
                modeLink(.exam)
            }
        }
        .navigationTitle("Üben")
        .onAppear {
            let nums = app.numbers
            if let first = nums.first, !nums.contains(from) { from = first }
            if let last = nums.last, !nums.contains(to) { to = last }
        }
    }

    private var rangePicker: some View {
        HStack {
            Picker("Von", selection: $from) {
                ForEach(app.numbers, id: \.self) { Text("L \($0)").tag($0) }
            }
            .onChange(of: from) { _, new in if to < new { to = new } }
            Picker("Bis", selection: $to) {
                ForEach(app.numbers, id: \.self) { Text("L \($0)").tag($0) }
            }
            .onChange(of: to) { _, new in if from > new { from = new } }
        }
    }

    private func modeLink(_ mode: PracticeMode) -> some View {
        NavigationLink {
            ModeLauncher(mode: mode, config: config)
        } label: {
            ModeRow(mode: mode)
        }
    }
}

struct ModeRow: View {
    let mode: PracticeMode
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mode.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(mode.color.gradient, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.title).font(.body)
                Text(mode.subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Startet einen Modus (baut die Fragen erst beim Öffnen)

struct ModeLauncher: View {
    let mode: PracticeMode
    let config: PracticeConfig
    @Environment(AppData.self) private var app
    @Environment(ProgressStore.self) private var progress

    @State private var questions: [Question]? = nil
    @State private var items: [VocabItem]? = nil
    @State private var examLength = 20
    @State private var examMinutes = 0
    @State private var examStarted = false

    var body: some View {
        Group {
            switch mode {
            case .flashcards, .typing, .matching, .daily, .mistakes:
                itemBased
            case .tables:
                TableDrillView(lessons: app.lessons(from: config.from, to: config.to))
            case .exam:
                examView
            default:
                questionBased
            }
        }
        .task { prepare() }
    }

    @ViewBuilder
    private var itemBased: some View {
        if let items {
            if items.isEmpty {
                emptyView
            } else if mode == .typing {
                TypingView(items: items, direction: config.direction)
            } else if mode == .matching {
                MatchingView(items: items)
            } else {
                FlashcardView(items: items, direction: config.direction)
            }
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    private var questionBased: some View {
        if let questions {
            if questions.isEmpty {
                emptyView
            } else {
                QuizSessionView(title: mode.title, questions: questions,
                                timeLimit: mode == .blitz ? 60 : nil,
                                autoAdvance: mode == .blitz,
                                autoSpeak: mode == .listening,
                                highscoreKey: mode == .blitz ? "blitz-\(config.from)-\(config.to)" : nil)
            }
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    private var examView: some View {
        if examStarted, let questions {
            QuizSessionView(title: "Schularbeit", questions: questions,
                            timeLimit: examMinutes > 0 ? examMinutes * 60 : nil,
                            examRange: config.rangeLabel)
        } else {
            Form {
                Section {
                    Text("Ein gemischter Test aus Vokabeln (beide Richtungen), Richtig/Falsch, Stammformen und Formen aus den Grammatik-Tabellen von \(config.rangeLabel).")
                        .font(.callout)
                }
                Section("Einstellungen") {
                    Picker("Fragen", selection: $examLength) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("30").tag(30)
                        Text("50").tag(50)
                    }
                    Picker("Zeitlimit", selection: $examMinutes) {
                        Text("Aus").tag(0)
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("20 min").tag(20)
                        Text("45 min").tag(45)
                    }
                }
                Section {
                    Button("Schularbeit starten") {
                        questions = QuestionFactory.exam(config: config, app: app, total: examLength)
                        examStarted = true
                    }
                }
                if !progress.data.tests.isEmpty {
                    Section("Letzte Ergebnisse") {
                        ForEach(progress.data.tests.prefix(5)) { t in
                            HStack {
                                Text(t.range)
                                Spacer()
                                Text("\(t.correct)/\(t.total) · Note \(t.grade)").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Schularbeit")
        }
    }

    private var emptyView: some View {
        ContentUnavailableView("Nichts zu üben",
                               systemImage: "tray",
                               description: Text(emptyText))
    }

    private var emptyText: String {
        switch mode {
        case .mistakes: return "Super – in diesem Bereich hast du gerade keine Fehler."
        case .daily: return "Heute ist nichts fällig. Komm morgen wieder!"
        default: return "In diesem Bereich gibt es dafür keine passenden Inhalte."
        }
    }

    private func prepare() {
        guard questions == nil, items == nil else { return }
        let pool = config.items(app)
        let all = app.allVocab
        switch mode {
        case .flashcards, .typing, .matching:
            items = config.limited(pool.shuffled())
        case .daily:
            items = progress.dueItems(in: all)
        case .mistakes:
            items = progress.mistakes(in: pool)
        case .multipleChoice:
            questions = config.limited(pool.shuffled()).map {
                QuestionFactory.vocabMC($0, pool: pool, all: all, direction: config.direction)
            }
        case .trueFalse:
            questions = config.limited(pool.shuffled()).map { QuestionFactory.trueFalse($0, pool: pool, all: all) }
        case .listening:
            questions = config.limited(pool.shuffled()).map { QuestionFactory.listening($0, pool: pool, all: all) }
        case .blitz:
            questions = (pool.shuffled() + pool.shuffled()).prefix(200).map {
                QuestionFactory.vocabMC($0, pool: pool, all: all, direction: config.direction)
            }
        case .stemForms:
            questions = config.limited(pool.shuffled().compactMap { QuestionFactory.stemForms($0, pool: pool, all: all) })
        case .foreignWords:
            questions = config.limited(pool.shuffled().compactMap { QuestionFactory.foreignWord($0, pool: pool, all: all) })
        case .formsIdentify:
            let lessons = app.lessons(from: config.from, to: config.to)
            questions = config.limited(QuestionFactory.identifyForms(lessons).shuffled())
        case .formsBuild:
            let lessons = app.lessons(from: config.from, to: config.to)
            questions = config.limited(QuestionFactory.buildForms(lessons).shuffled())
        case .tables, .exam:
            break
        }
    }
}
