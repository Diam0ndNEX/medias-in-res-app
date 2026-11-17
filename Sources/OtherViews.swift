import SwiftUI
import UniformTypeIdentifiers

// MARK: - Nachschlagen

struct SearchView: View {
    @Environment(AppData.self) private var app
    @Environment(ProgressStore.self) private var progress
    @State private var query = ""

    private var vocabHits: [VocabItem] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }
        return app.allVocab.filter {
            $0.la.lowercased().contains(q) || $0.de.lowercased().contains(q)
                || $0.forms.lowercased().contains(q) || $0.note.lowercased().contains(q)
        }
    }

    private var grammarHits: [(Lesson, GrammarSection)] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        var out: [(Lesson, GrammarSection)] = []
        for l in app.lessons {
            for s in l.grammar {
                if q.isEmpty || s.title.lowercased().contains(q) || sectionText(s).contains(q) {
                    out.append((l, s))
                }
            }
        }
        return out
    }

    private func sectionText(_ s: GrammarSection) -> String {
        var parts: [String] = []
        for b in s.blocks {
            parts.append(b.text ?? "")
            parts += b.items ?? []
            parts += (b.rows ?? []).flatMap { $0 }
        }
        return parts.joined(separator: " ").lowercased()
    }

    var body: some View {
        List {
            if !vocabHits.isEmpty {
                Section("Vokabeln (\(vocabHits.count))") {
                    ForEach(vocabHits.prefix(100)) { v in
                        VocabRow(item: v, hideGerman: false, box: progress.box(for: v), showLesson: true)
                    }
                }
            }
            Section(query.isEmpty ? "Grammatik-Register" : "Grammatik") {
                ForEach(Array(grammarHits.enumerated()), id: \.offset) { _, hit in
                    NavigationLink {
                        ScrollView {
                            GrammarSectionContent(section: hit.1).padding()
                        }
                        .navigationTitle("Lektion \(hit.0.number)")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Text("L\(hit.0.number)").font(.caption.bold()).foregroundStyle(.secondary)
                                .frame(width: 32, alignment: .leading)
                            Text(hit.1.title)
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Latein oder Deutsch suchen")
        .navigationTitle("Nachschlagen")
    }
}

// MARK: - Statistik

struct StatsView: View {
    @Environment(AppData.self) private var app
    @Environment(ProgressStore.self) private var progress
    @AppStorage("dailyGoal") private var dailyGoal = 30

    var body: some View {
        let all = app.allVocab
        let mastered = all.filter { progress.box(for: $0) >= 4 }.count
        let seen = progress.seen(in: all)
        List {
            Section {
                HStack(spacing: 0) {
                    statTile("\(progress.streak)", "Tage Serie", "flame.fill", .orange)
                    statTile("\(progress.todayCount)/\(dailyGoal)", "Heute", "target", .blue)
                    statTile("\(mastered)", "sitzen", "checkmark.seal.fill", .green)
                }
                SwiftUI.ProgressView(value: min(1, Double(progress.todayCount) / Double(max(dailyGoal, 1)))) {
                    Text(progress.todayCount >= dailyGoal ? "Tagesziel erreicht! 🎉" : "Tagesziel")
                        .font(.caption)
                }
            }
            Section("Abzeichen") {
                BadgesGrid()
            }
            Section("Letzte 7 Tage") {
                let days = progress.lastDays(7)
                let maxV = max(days.map { $0.1 }.max() ?? 1, 1)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, d in
                        VStack {
                            Text("\(d.1)").font(.caption2).foregroundStyle(.secondary)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.gradient)
                                .frame(height: max(4, CGFloat(d.1) / CGFloat(maxV) * 80))
                            Text(d.0).font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
            }
            Section("Gesamt") {
                row("Vokabeln im Buch", "\(all.count)")
                row("Schon geübt", "\(seen)")
                row("Sitzen (Box 4–5)", "\(mastered)")
                row("Beantwortete Fragen", "\(progress.totalAnswered)")
            }
            Section("Fortschritt pro Lektion") {
                ForEach(app.lessons) { l in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(l.number). \(l.title)").lineLimit(1)
                            Spacer()
                            Text("\(Int(progress.mastered(in: l.vocab) * 100)) %").foregroundStyle(.secondary)
                        }
                        SwiftUI.ProgressView(value: progress.mastered(in: l.vocab)).tint(.green)
                    }
                }
            }
            let hard = progress.hardest(in: all)
            if !hard.isEmpty {
                Section("Schwierigste Wörter") {
                    ForEach(hard) { v in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(v.la).font(.headline)
                                Text(v.de).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("✗ \(progress.stats(for: v).wrong)").foregroundStyle(.red)
                        }
                    }
                }
            }
            if !progress.data.tests.isEmpty {
                Section("Schularbeiten") {
                    ForEach(progress.data.tests.prefix(20)) { t in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(t.range)
                                Text(t.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(t.correct)/\(t.total)")
                            Text("\(t.grade)").font(.headline)
                                .frame(width: 28, height: 28)
                                .background(gradeColor(t.grade).opacity(0.25), in: Circle())
                        }
                    }
                }
            }
            if !progress.data.highscores.isEmpty {
                Section("Rekorde Blitzrunde") {
                    ForEach(progress.data.highscores.sorted { $0.key < $1.key }, id: \.key) { pair in
                        row(pair.key.replacingOccurrences(of: "blitz-", with: "Lektion ").replacingOccurrences(of: "-", with: "–"), "\(pair.value)")
                    }
                }
            }
        }
        .navigationTitle("Statistik")
    }

    private func statTile(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private func row(_ l: String, _ r: String) -> some View {
        HStack { Text(l); Spacer(); Text(r).foregroundStyle(.secondary) }
    }

    private func gradeColor(_ g: Int) -> Color {
        switch g {
        case 1, 2: return .green
        case 3: return .yellow
        case 4: return .orange
        default: return .red
        }
    }
}

// MARK: - Einstellungen

struct SettingsView: View {
    @Environment(ProgressStore.self) private var progress
    @AppStorage("typingEnabled") private var typingEnabled = false
    @AppStorage("tolerantTyping") private var tolerant = true
    @AppStorage("hapticsOn") private var haptics = true
    @AppStorage("dailyGoal") private var dailyGoal = 30
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderHour") private var reminderHour = 18
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var confirmReset = false
    @State private var importing = false
    @State private var importMessage: String? = nil

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "–"
        let b = info?["CFBundleVersion"] as? String ?? ""
        return b.isEmpty ? v : "\(v) (\(b))"
    }

    private var reminderDate: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()) ?? Date()
        } set: { d in
            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
            reminderHour = c.hour ?? 18
            reminderMinute = c.minute ?? 0
            if reminderOn { Reminder.schedule(hour: reminderHour, minute: reminderMinute) }
        }
    }

    var body: some View {
        Form {
            Section {
                Toggle("Eintippen-Modus anzeigen", isOn: $typingEnabled)
                if typingEnabled {
                    Toggle("Tolerante Prüfung", isOn: $tolerant)
                }
            } header: {
                Text("Üben")
            } footer: {
                Text("Standardmäßig wird alles durch Antippen und Wischen geübt. Tolerant heißt: kleine Tippfehler und eine von mehreren Bedeutungen zählen als richtig.")
            }
            Section("Tagesziel") {
                Stepper("\(dailyGoal) Fragen pro Tag", value: $dailyGoal, in: 10...200, step: 10)
            }
            Section("Erinnerung") {
                Toggle("Tägliche Erinnerung", isOn: $reminderOn)
                    .onChange(of: reminderOn) { _, on in
                        if on { Reminder.schedule(hour: reminderHour, minute: reminderMinute) } else { Reminder.cancel() }
                    }
                if reminderOn {
                    DatePicker("Uhrzeit", selection: reminderDate, displayedComponents: .hourAndMinute)
                }
            }
            Section("Allgemein") {
                Toggle("Vibration (Haptik)", isOn: $haptics)
            }
            Section {
                if let url = progress.exportFile() {
                    ShareLink(item: url) { Label("Fortschritt sichern (exportieren)", systemImage: "square.and.arrow.up") }
                }
                Button {
                    importing = true
                } label: { Label("Fortschritt wiederherstellen", systemImage: "square.and.arrow.down") }
                if let m = importMessage { Text(m).font(.caption) }
            } header: {
                Text("Backup")
            } footer: {
                Text("Speichere die Datei z. B. in „Dateien“, bevor du die App neu installierst oder neu signierst.")
            }
            Section {
                Button("Gesamten Fortschritt löschen", role: .destructive) { confirmReset = true }
            }
            Section("Über") {
                LabeledContent("Version", value: appVersion)
                Text("Lern-App zum Lateinbuch „Medias in Res!“ (Lektion 1–30). Nur für den privaten Gebrauch.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Einstellungen")
        .confirmationDialog("Wirklich alles löschen?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) { progress.resetAll() }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result {
                importMessage = progress.importFile(url) ? "Fortschritt wiederhergestellt ✅" : "Datei konnte nicht gelesen werden."
            }
        }
    }
}


// MARK: - Abzeichen

struct Badge: Identifiable {
    let id: String
    let icon: String
    let title: String
    let detail: String
    let earned: Bool
}

struct BadgesGrid: View {
    @Environment(AppData.self) private var app
    @Environment(ProgressStore.self) private var progress

    private var badges: [Badge] {
        let all = app.allVocab
        let masteredCount = all.filter { progress.box(for: $0) >= 4 }.count
        let lessonDone = app.lessons.filter { progress.mastered(in: $0.vocab) >= 0.999 }.count
        func range(_ a: Int, _ b: Int) -> Bool {
            let ls = app.lessons(from: a, to: b)
            return !ls.isEmpty && ls.allSatisfy { progress.mastered(in: $0.vocab) >= 0.8 }
        }
        let answered = progress.totalAnswered
        let longest = progress.longestStreak
        let bestBlitz = progress.data.highscores.values.max() ?? 0
        return [
            Badge(id: "start", icon: "flag.fill", title: "Medias in res", detail: "Erste Frage beantwortet", earned: answered >= 1),
            Badge(id: "fleiss", icon: "figure.walk", title: "Fleißig", detail: "500 Fragen beantwortet", earned: answered >= 500),
            Badge(id: "marathon", icon: "figure.run", title: "Marathon", detail: "2000 Fragen beantwortet", earned: answered >= 2000),
            Badge(id: "s3", icon: "flame", title: "Funke", detail: "3 Tage in Folge", earned: longest >= 3),
            Badge(id: "s7", icon: "flame.fill", title: "Feuer", detail: "7 Tage in Folge", earned: longest >= 7),
            Badge(id: "s30", icon: "sun.max.fill", title: "Sol invictus", detail: "30 Tage in Folge", earned: longest >= 30),
            Badge(id: "lesson", icon: "book.closed.fill", title: "Lektion gemeistert", detail: "Alle Vokabeln einer Lektion sitzen", earned: lessonDone >= 1),
            Badge(id: "v100", icon: "star.circle.fill", title: "Centurio", detail: "100 Vokabeln sitzen", earned: masteredCount >= 100),
            Badge(id: "v500", icon: "crown.fill", title: "Imperator", detail: "500 Vokabeln sitzen", earned: masteredCount >= 500),
            Badge(id: "half", icon: "building.columns", title: "Halbzeit", detail: "Lektion 1–15 zu 80 % gelernt", earned: range(1, 15)),
            Badge(id: "all", icon: "laurel.leading", title: "Veni, vidi, vici", detail: "Alle 30 Lektionen zu 80 % gelernt", earned: range(1, 30)),
            Badge(id: "einser", icon: "graduationcap.fill", title: "Summa cum laude", detail: "Schularbeit mit Note 1", earned: progress.bestGrade == 1),
            Badge(id: "blitz", icon: "bolt.fill", title: "Blitzmerker", detail: "30 richtige in einer Blitzrunde", earned: bestBlitz >= 30),
        ]
    }

    var body: some View {
        let list = badges
        VStack(alignment: .leading, spacing: 8) {
            Text("\(list.filter { $0.earned }.count) von \(list.count) freigeschaltet")
                .font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 12) {
                ForEach(list) { b in
                    VStack(spacing: 4) {
                        Image(systemName: b.icon)
                            .font(.title2)
                            .foregroundStyle(b.earned ? Color.white : Color.secondary)
                            .frame(width: 48, height: 48)
                            .background(b.earned ? AnyShapeStyle(Color.orange.gradient) : AnyShapeStyle(Color.secondary.opacity(0.15)),
                                        in: Circle())
                        Text(b.title).font(.caption.bold()).multilineTextAlignment(.center)
                        Text(b.detail).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .opacity(b.earned ? 1 : 0.55)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Einführung beim ersten Start

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Salve! 👋").font(.largeTitle.bold())
            Text("Alles aus „Medias in Res!“ – Lektion 1 bis 30 – zum Lernen und Wiederholen.")
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 16) {
                tip("book", "Lektionen", "Vokabeln und Grammatik jeder Lektion zum Nachlesen.")
                tip("brain.head.profile", "Üben", "Wähle z. B. Lektion 5–10 und übe mit Karteikarten, Quiz, Hören, Formen oder Schularbeit.")
                tip("calendar.badge.clock", "Täglich wiederholen", "Die App merkt sich, was du kannst, und zeigt dir fällige Wörter.")
                tip("star", "Merkliste", "In der Vokabelliste nach links wischen, um ein Wort zu merken.")
                tip("square.and.arrow.up", "Backup", "Sichere deinen Fortschritt in den Einstellungen, bevor du neu signierst.")
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Los geht’s – medias in res!").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
    }

    private func tip(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.title2).foregroundStyle(Color.accentColor).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
