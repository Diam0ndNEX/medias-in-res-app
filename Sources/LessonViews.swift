import SwiftUI

struct LessonListView: View {
    @Environment(AppData.self) private var app
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        List {
            if app.lessons.isEmpty {
                Text("Keine Lektionen gefunden.")
            } else {
                Section { HomeHeader() }
            }
            ForEach(app.units, id: \.self) { unit in
                Section(unit) {
                    ForEach(app.lessons.filter { $0.unit == unit }) { lesson in
                        NavigationLink(value: lesson) { LessonRow(lesson: lesson) }
                    }
                }
            }
        }
        .navigationTitle("Medias in Res")
        .navigationDestination(for: Lesson.self) { LessonDetailView(lesson: $0) }
    }
}

struct LessonRow: View {
    let lesson: Lesson
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        let mastered = progress.mastered(in: lesson.vocab)
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                Circle().trim(from: 0, to: mastered)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(lesson.number)").font(.headline)
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title).font(.headline)
                Text("\(lesson.vocab.count) Vokabeln · \(lesson.grammar.count) Grammatik-Themen")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct LessonDetailView: View {
    let lesson: Lesson
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text("Vokabeln").tag(0)
                Text("Grammatik").tag(1)
                Text("Üben").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            switch tab {
            case 0: VocabListView(lesson: lesson)
            case 1: GrammarView(sections: lesson.grammar)
            default: LessonPracticeView(lesson: lesson)
            }
        }
        .navigationTitle("Lektion \(lesson.number): \(lesson.title)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LessonPracticeView: View {
    let lesson: Lesson
    @AppStorage("typingEnabled") private var typingEnabled = false

    private var config: PracticeConfig {
        PracticeConfig(from: lesson.number, to: lesson.number, pos: "Alle", direction: .mixed, count: 0)
    }

    var body: some View {
        List {
            Section("Vokabeln dieser Lektion") {
                link(.flashcards)
                link(.multipleChoice)
                link(.trueFalse)
                link(.matching)
                link(.listening)
                if typingEnabled { link(.typing) }
                link(.stemForms)
                link(.foreignWords)
                link(.mistakes)
            }
            Section("Grammatik dieser Lektion") {
                link(.formsIdentify)
                link(.formsBuild)
                link(.tables)
            }
            Section {
                link(.exam)
            }
        }
    }

    private func link(_ mode: PracticeMode) -> some View {
        NavigationLink {
            ModeLauncher(mode: mode, config: config)
        } label: {
            ModeRow(mode: mode)
        }
    }
}

struct VocabListView: View {
    let lesson: Lesson
    @Environment(ProgressStore.self) private var progress
    @State private var hideGerman = false

    var body: some View {
        List {
            Section {
                Toggle("Deutsch verdecken", isOn: $hideGerman)
            }
            Section {
                ForEach(lesson.vocab) { v in
                    VocabRow(item: v, hideGerman: hideGerman, box: progress.box(for: v))
                }
            } footer: {
                if let n = lesson.vocabNote { Text(n) }
            }
        }
    }
}

struct VocabRow: View {
    let item: VocabItem
    let hideGerman: Bool
    let box: Int
    var showLesson = false
    @Environment(ProgressStore.self) private var progress
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.la).font(.headline)
                if !item.forms.isEmpty {
                    Text(item.forms).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if progress.isStarred(item) { Image(systemName: "star.fill").font(.caption).foregroundStyle(.orange) }
                if showLesson { Text("L\(item.lesson)").font(.caption2).foregroundStyle(.secondary) }
                BoxBadge(box: box)
            }
            Text(hideGerman && !revealed ? "• • •" : item.de)
            if !item.note.isEmpty && (!hideGerman || revealed) {
                Text(item.note).font(.caption).foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { revealed.toggle() }
        .swipeActions(edge: .leading) {
            Button {
                Speaker.shared.speakLatin(item.speakable)
            } label: { Label("Anhören", systemImage: "speaker.wave.2") }
            .tint(.purple)
        }
        .swipeActions(edge: .trailing) {
            Button {
                progress.toggleStar(item)
                Haptics.tap()
            } label: {
                Label(progress.isStarred(item) ? "Entfernen" : "Merken",
                      systemImage: progress.isStarred(item) ? "star.slash" : "star")
            }
            .tint(.orange)
        }
    }
}

struct BoxBadge: View {
    let box: Int
    var body: some View {
        if box > 0 {
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Circle().fill(i <= box ? Color.green : Color.secondary.opacity(0.25))
                        .frame(width: 5, height: 5)
                }
            }
        }
    }
}

struct GrammarView: View {
    let sections: [GrammarSection]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(sections) { section in
                    GrammarSectionContent(section: section)
                }
            }
            .padding()
        }
    }
}

struct GrammarSectionContent: View {
    let section: GrammarSection
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title).font(.title3.bold())
            ForEach(section.blocks) { BlockView(block: $0) }
        }
    }
}

struct BlockView: View {
    let block: Block

    var body: some View {
        switch block.type {
        case "list":
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array((block.items ?? []).enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•")
                        Text(item)
                    }
                }
            }
        case "tip":
            callout(label: "TIPP", text: block.text ?? "", color: .green)
        case "note":
            callout(label: "NOTA BENE", text: block.text ?? "", color: .orange)
        case "table":
            TableBlock(headers: block.headers ?? [], rows: block.rows ?? [])
        default:
            Text(block.text ?? "")
        }
    }

    private func callout(label: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption.bold()).foregroundStyle(color)
            Text(text)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct TableBlock: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                if !headers.isEmpty {
                    GridRow {
                        ForEach(Array(headers.enumerated()), id: \.offset) { _, h in
                            Text(h).font(.caption.bold()).foregroundStyle(.secondary)
                        }
                    }
                    Divider()
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { i, cell in
                            Text(cell).italic(i > 0).fontWeight(i == 0 ? .semibold : .regular)
                        }
                    }
                }
            }
            .padding(10)
        }
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}


/// Oberer Bereich im Lektionen-Tab: Vokabel des Tages, Weiterlernen, fällige Karten.
struct HomeHeader: View {
    @Environment(AppData.self) private var app
    @Environment(ProgressStore.self) private var progress
    @State private var showWord = false

    private var nextLesson: Lesson? {
        app.lessons.first { progress.mastered(in: $0.vocab) < 0.8 } ?? app.lessons.last
    }

    var body: some View {
        if let word = DailyWord.pick(from: app.allVocab) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Vokabel des Tages", systemImage: "sun.max.fill")
                    .font(.caption.bold()).foregroundStyle(.orange)
                HStack(alignment: .firstTextBaseline) {
                    Text(word.la).font(.title2.bold())
                    Spacer()
                    Button {
                        Speaker.shared.speakLatin(word.speakable)
                    } label: { Image(systemName: "speaker.wave.2.fill") }
                    .buttonStyle(.borderless)
                }
                if !word.forms.isEmpty { Text(word.forms).font(.subheadline).foregroundStyle(.secondary) }
                Text(showWord ? word.de : "Tippen zum Aufdecken")
                    .foregroundStyle(showWord ? .primary : .secondary)
                if showWord && !word.note.isEmpty {
                    Text(word.note).font(.caption).foregroundStyle(.secondary)
                }
                Text("Lektion \(word.lesson)").font(.caption2).foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { showWord.toggle() } }
        }
        if let next = nextLesson {
            NavigationLink(value: next) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Weiterlernen").font(.headline)
                        Text("Lektion \(next.number): \(next.title) · \(Int(progress.mastered(in: next.vocab) * 100)) % sitzen")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "arrow.right.circle.fill").foregroundStyle(Color.accentColor)
                }
            }
        }
        HStack {
            Label("\(progress.streak) Tage", systemImage: "flame.fill").foregroundStyle(.orange)
            Spacer()
            Label("\(progress.dueCount(in: app.allVocab)) fällig", systemImage: "calendar.badge.clock")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}
