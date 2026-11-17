import SwiftUI

struct AnsweredQuestion: Identifiable {
    let id = UUID()
    let question: Question
    let chosen: Int
    var correct: Bool { chosen == question.correct }
}

/// Gemeinsame Ansicht für alle Auswahl-Modi (Multiple Choice, Richtig/Falsch, Hören,
/// Stammformen, Formen, Blitzrunde, Schularbeit …).
struct QuizSessionView: View {
    let title: String
    var timeLimit: Int? = nil          // Sekunden für die ganze Runde
    var autoAdvance: Bool = false
    var autoSpeak: Bool = false
    var highscoreKey: String? = nil
    var examRange: String? = nil       // gesetzt → Schularbeit mit Note

    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss

    @State private var deck: [Question]
    @State private var index = 0
    @State private var chosen: Int? = nil
    @State private var answered: [AnsweredQuestion] = []
    @State private var remaining: Int = 0
    @State private var finished = false
    @State private var newRecord = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(title: String, questions: [Question], timeLimit: Int? = nil, autoAdvance: Bool = false,
         autoSpeak: Bool = false, highscoreKey: String? = nil, examRange: String? = nil) {
        self.title = title
        self.timeLimit = timeLimit
        self.autoAdvance = autoAdvance
        self.autoSpeak = autoSpeak
        self.highscoreKey = highscoreKey
        self.examRange = examRange
        _deck = State(initialValue: questions)
        _remaining = State(initialValue: timeLimit ?? 0)
    }

    private var current: Question? { index < deck.count ? deck[index] : nil }
    private var correctCount: Int { answered.filter { $0.correct }.count }

    var body: some View {
        Group {
            if finished || current == nil {
                resultView
            } else if let q = current {
                questionView(q)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in tick() }
        .onAppear { speakIfNeeded() }
    }

    // MARK: Frage

    @ViewBuilder
    private func questionView(_ q: Question) -> some View {
        VStack(spacing: 16) {
            header
            Spacer(minLength: 0)
            promptCard(q)
            Spacer(minLength: 0)
            optionsGrid(q)
            if chosen != nil && !autoAdvance {
                Button {
                    next()
                } label: {
                    Text(index + 1 < deck.count ? "Weiter" : "Fertig").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
    }

    private var header: some View {
        HStack {
            if timeLimit != nil {
                Label("\(remaining) s", systemImage: "timer")
                    .foregroundStyle(remaining <= 10 ? .red : .primary)
                    .monospacedDigit()
            } else {
                Text("Frage \(min(index + 1, deck.count)) / \(deck.count)")
            }
            Spacer()
            Label("\(correctCount)", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        }
        .font(.subheadline)
    }

    private func promptCard(_ q: Question) -> some View {
        VStack(spacing: 10) {
            if !q.category.isEmpty {
                Text(q.category.uppercased()).font(.caption2.bold()).foregroundStyle(.secondary)
            }
            Text(q.prompt)
                .font(q.prompt.count > 40 ? .title3 : .largeTitle).bold()
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
            if !q.hint.isEmpty {
                Text(q.hint).font(.headline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            if let s = q.speakLatin {
                Button {
                    Speaker.shared.speakLatin(s)
                } label: {
                    Label("Anhören", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
            }
            if chosen != nil && !q.explanation.isEmpty {
                Text(q.explanation).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }

    private func optionsGrid(_ q: Question) -> some View {
        VStack(spacing: 10) {
            ForEach(q.options.indices, id: \.self) { i in
                Button {
                    choose(i, in: q)
                } label: {
                    Text(q.options[i])
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(.bordered)
                .tint(tint(for: i, in: q))
                .disabled(chosen != nil)
            }
        }
    }

    private func tint(for i: Int, in q: Question) -> Color {
        guard let c = chosen else { return .accentColor }
        if i == q.correct { return .green }
        if i == c { return .red }
        return .gray
    }

    // MARK: Ergebnis

    private var resultView: some View {
        let total = examRange != nil ? deck.count : answered.count
        let grade = Grading.grade(correct: correctCount, total: total)
        let wrong = answered.filter { !$0.correct }
        return List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: examRange != nil ? "graduationcap.fill" : "checkmark.seal.fill")
                        .font(.system(size: 50)).foregroundStyle(.green)
                    Text("\(correctCount) von \(total) richtig").font(.title2.bold())
                    if examRange != nil {
                        Text("Note: \(grade) – \(Grading.label(grade))").font(.headline)
                    }
                    if newRecord { Text("🏆 Neuer Rekord!").font(.headline) }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            if !wrong.isEmpty {
                Section("Fehler (\(wrong.count))") {
                    ForEach(wrong) { a in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.question.prompt).font(.headline)
                            if !a.question.hint.isEmpty && a.question.prompt != "🔊" {
                                Text(a.question.hint).font(.caption).foregroundStyle(.secondary)
                            }
                            Text("Richtig: \(a.question.options[a.question.correct])").foregroundStyle(.green)
                            Text("Deine Antwort: \(a.question.options[a.chosen])").foregroundStyle(.red).font(.caption)
                        }
                    }
                }
                Section {
                    Button("Fehler nochmal üben") { restart(with: wrong.map { $0.question }) }
                }
            }
            Section {
                Button("Fertig") { dismiss() }
            }
        }
    }

    // MARK: Logik

    private func choose(_ i: Int, in q: Question) {
        guard chosen == nil else { return }
        chosen = i
        let ok = i == q.correct
        Haptics.result(ok)
        answered.append(AnsweredQuestion(question: q, chosen: i))
        if let item = q.item { progress.record(item, knew: ok) } else { progress.countActivity() }
        if autoAdvance {
            DispatchQueue.main.asyncAfter(deadline: .now() + (ok ? 0.35 : 0.9)) { next() }
        }
    }

    private func next() {
        chosen = nil
        if index + 1 < deck.count {
            index += 1
            speakIfNeeded()
        } else {
            finish()
        }
    }

    private func tick() {
        guard timeLimit != nil, !finished, current != nil else { return }
        if remaining > 0 { remaining -= 1 }
        if remaining == 0 { finish() }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        if let key = highscoreKey { newRecord = progress.submitHighscore(key, correctCount) }
        if let range = examRange {
            let total = deck.count
            progress.addTest(TestResult(date: Date(), range: range, correct: correctCount, total: total,
                                        grade: Grading.grade(correct: correctCount, total: total)))
        }
    }

    private func restart(with questions: [Question]) {
        deck = questions.shuffled()
        index = 0
        chosen = nil
        answered = []
        finished = false
        newRecord = false
        remaining = timeLimit ?? 0
        speakIfNeeded()
    }

    private func speakIfNeeded() {
        guard autoSpeak, let s = current?.speakLatin else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { Speaker.shared.speakLatin(s) }
    }
}
