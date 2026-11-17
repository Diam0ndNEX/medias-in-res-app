import SwiftUI

struct TrainerSetupView: View {
    let lessons: [Lesson]
    @State private var from = 1
    @State private var to = 1
    @State private var latinToGerman = true
    @State private var started = false

    private var numbers: [Int] { lessons.map(\.number) }
    private var selected: [VocabItem] {
        lessons.filter { $0.number >= from && $0.number <= to }.flatMap(\.vocab)
    }

    var body: some View {
        Form {
            Section("Lektionen") {
                Picker("Von", selection: $from) {
                    ForEach(numbers, id: \.self) { Text("Lektion \($0)").tag($0) }
                }
                Picker("Bis", selection: $to) {
                    ForEach(numbers, id: \.self) { Text("Lektion \($0)").tag($0) }
                }
            }
            Section("Richtung") {
                Picker("Richtung", selection: $latinToGerman) {
                    Text("Latein → Deutsch").tag(true)
                    Text("Deutsch → Latein").tag(false)
                }
                .pickerStyle(.segmented)
            }
            Section {
                Text("\(selected.count) Vokabeln ausgewählt")
                Button("Starten") { started = true }
                    .disabled(selected.isEmpty)
            }
        }
        .navigationTitle("Vokabeln üben")
        .onChange(of: from) { _, new in if to < new { to = new } }
        .onAppear {
            if let first = numbers.first, !numbers.contains(from) { from = first; to = first }
        }
        .navigationDestination(isPresented: $started) {
            FlashcardView(items: selected, latinToGerman: latinToGerman)
        }
    }
}

struct FlashcardView: View {
    let items: [VocabItem]
    let latinToGerman: Bool
    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [VocabItem] = []
    @State private var revealed = false
    @State private var knew = 0
    @State private var total = 0

    var body: some View {
        VStack(spacing: 24) {
            if let card = queue.first {
                Text("Noch \(queue.count) Karten").font(.caption).foregroundStyle(.secondary)
                Spacer()
                VStack(spacing: 12) {
                    Text(latinToGerman ? card.la : card.de)
                        .font(.largeTitle.bold()).multilineTextAlignment(.center)
                    if latinToGerman && !card.forms.isEmpty {
                        Text(card.forms).foregroundStyle(.secondary)
                    }
                    if revealed {
                        Divider()
                        Text(latinToGerman ? card.de : card.la)
                            .font(.title2).multilineTextAlignment(.center)
                        if !latinToGerman && !card.forms.isEmpty {
                            Text(card.forms).foregroundStyle(.secondary)
                        }
                        if !card.note.isEmpty {
                            Text(card.note).font(.footnote).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                Spacer()

                if revealed {
                    HStack(spacing: 16) {
                        Button { answer(card, knew: false) } label: {
                            Label("Nicht gewusst", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).tint(.red)
                        Button { answer(card, knew: true) } label: {
                            Label("Gewusst", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).tint(.green)
                    }
                    .padding(.horizontal)
                } else {
                    Button { revealed = true } label: {
                        Text("Aufdecken").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
            } else {
                Spacer()
                Image(systemName: "checkmark.seal.fill").font(.system(size: 60)).foregroundStyle(.green)
                Text("Geschafft!").font(.title.bold())
                Text("\(knew) von \(total) Antworten gewusst")
                Button("Fertig") { dismiss() }.buttonStyle(.borderedProminent)
                Spacer()
            }
        }
        .padding(.vertical)
        .navigationTitle("Üben")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if queue.isEmpty && total == 0 { buildQueue() } }
    }

    private func buildQueue() {
        // schwächere Boxen zuerst, innerhalb einer Box zufällig
        queue = items.shuffled().sorted { progress.box(for: $0) < progress.box(for: $1) }
    }

    private func answer(_ card: VocabItem, knew isKnown: Bool) {
        progress.record(card, knew: isKnown)
        total += 1
        if isKnown { knew += 1 }
        revealed = false
        queue.removeFirst()
        if !isKnown {
            // später in dieser Runde nochmal
            let pos = min(3, queue.count)
            queue.insert(card, at: pos)
        }
    }
}

struct ProgressView2: View {
    let lessons: [Lesson]
    @Environment(ProgressStore.self) private var progress
    @State private var confirmReset = false

    var body: some View {
        List {
            Section("Vokabeln – „sitzt“ (Box 4–5)") {
                ForEach(lessons) { lesson in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Lektion \(lesson.number): \(lesson.title)")
                            Spacer()
                            Text("\(Int(progress.mastered(in: lesson.vocab) * 100)) %")
                                .foregroundStyle(.secondary)
                        }
                        SwiftUI.ProgressView(value: progress.mastered(in: lesson.vocab))
                    }
                }
            }
            Section {
                Button("Fortschritt zurücksetzen", role: .destructive) { confirmReset = true }
            }
        }
        .navigationTitle("Fortschritt")
        .confirmationDialog("Wirklich alles zurücksetzen?", isPresented: $confirmReset) {
            Button("Zurücksetzen", role: .destructive) { progress.resetAll() }
        }
    }
}
