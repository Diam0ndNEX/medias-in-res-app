import SwiftUI

// MARK: - Karteikarten

struct FlashcardView: View {
    let items: [VocabItem]
    let direction: Direction
    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [VocabItem] = []
    @State private var revealed = false
    @State private var knew = 0
    @State private var total = 0
    @State private var started = false
    @State private var currentDir: Direction = .laDe
    @State private var offset: CGFloat = 0

    var body: some View {
        VStack(spacing: 20) {
            if let card = queue.first {
                Text("Noch \(queue.count) Karten · wische → gewusst, ← nicht gewusst")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                cardView(card)
                    .offset(x: offset)
                    .rotationEffect(.degrees(Double(offset / 20)))
                    .gesture(
                        DragGesture()
                            .onChanged { v in if revealed { offset = v.translation.width } }
                            .onEnded { v in
                                guard revealed else { return }
                                if v.translation.width > 100 { answer(card, knew: true) }
                                else if v.translation.width < -100 { answer(card, knew: false) }
                                withAnimation { offset = 0 }
                            }
                    )
                    .onTapGesture { withAnimation { revealed = true } }
                Spacer()
                buttons(card)
            } else if started {
                Spacer()
                Image(systemName: "checkmark.seal.fill").font(.system(size: 60)).foregroundStyle(.green)
                Text("Geschafft!").font(.title.bold())
                Text("\(knew) von \(total) Antworten gewusst")
                Button("Fertig") { dismiss() }.buttonStyle(.borderedProminent)
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Karteikarten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !started else { return }
            started = true
            queue = items.shuffled().sorted { progress.box(for: $0) < progress.box(for: $1) }
            currentDir = direction.resolve()
        }
    }

    private func cardView(_ card: VocabItem) -> some View {
        let front = currentDir == .laDe
        return VStack(spacing: 12) {
            Text(front ? card.la : card.de)
                .font(.largeTitle.bold()).multilineTextAlignment(.center).minimumScaleFactor(0.5)
            if front && !card.forms.isEmpty { Text(card.forms).foregroundStyle(.secondary) }
            if revealed {
                Divider()
                Text(front ? card.de : card.la).font(.title2).multilineTextAlignment(.center)
                if !front && !card.forms.isEmpty { Text(card.forms).foregroundStyle(.secondary) }
                if !card.note.isEmpty {
                    Text(card.note).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
            } else {
                Text("Tippen zum Aufdecken").font(.caption).foregroundStyle(.tertiary)
            }
            HStack {
                Button {
                    Speaker.shared.speakLatin(card.speakable)
                } label: { Image(systemName: "speaker.wave.2.fill") }
                .buttonStyle(.bordered)
                Button {
                    progress.toggleStar(card)
                    Haptics.tap()
                } label: { Image(systemName: progress.isStarred(card) ? "star.fill" : "star") }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
            Text("Lektion \(card.lesson) · Box \(progress.box(for: card))")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 20))
    }

    private var cardColor: Color {
        if offset > 40 { return .green.opacity(0.2) }
        if offset < -40 { return .red.opacity(0.2) }
        return Color.secondary.opacity(0.1)
    }

    @ViewBuilder
    private func buttons(_ card: VocabItem) -> some View {
        if revealed {
            HStack(spacing: 16) {
                Button { answer(card, knew: false) } label: {
                    Label("Nicht gewusst", systemImage: "xmark").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.red)
                Button { answer(card, knew: true) } label: {
                    Label("Gewusst", systemImage: "checkmark").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.green)
            }
            .controlSize(.large)
        } else {
            Button { withAnimation { revealed = true } } label: {
                Text("Aufdecken").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
        }
    }

    private func answer(_ card: VocabItem, knew isKnown: Bool) {
        Haptics.result(isKnown)
        progress.record(card, knew: isKnown)
        total += 1
        if isKnown { knew += 1 }
        revealed = false
        guard !queue.isEmpty else { return }
        queue.removeFirst()
        if !isKnown { queue.insert(card, at: min(3, queue.count)) }
        currentDir = direction.resolve()
    }
}

// MARK: - Eintippen

struct TypingView: View {
    let items: [VocabItem]
    let direction: Direction
    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tolerantTyping") private var tolerant = true

    @State private var queue: [VocabItem] = []
    @State private var input = ""
    @State private var result: Bool? = nil
    @State private var right = 0
    @State private var total = 0
    @State private var started = false
    @State private var dir: Direction = .laDe
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 16) {
            if let item = queue.first {
                Text("Noch \(queue.count) · \(right) / \(total) richtig").font(.caption).foregroundStyle(.secondary)
                VStack(spacing: 8) {
                    Text(dir == .laDe ? item.la : item.de).font(.largeTitle.bold()).multilineTextAlignment(.center)
                    if dir == .laDe && !item.forms.isEmpty { Text(item.forms).foregroundStyle(.secondary) }
                    Text(dir == .laDe ? "Deutsche Bedeutung eintippen" : "Lateinisches Wort eintippen")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

                TextField("Antwort", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focused)
                    .onSubmit { result == nil ? check(item) : next() }
                    .disabled(result != nil)

                if let ok = result {
                    VStack(spacing: 4) {
                        Text(ok ? "Richtig! ✅" : "Leider falsch ❌").font(.headline)
                            .foregroundStyle(ok ? .green : .red)
                        Text("\(item.la) = \(item.de)").multilineTextAlignment(.center)
                        if !item.forms.isEmpty { Text(item.forms).font(.caption).foregroundStyle(.secondary) }
                    }
                    HStack {
                        if !ok {
                            Button("Doch gewusst") { override(item) }.buttonStyle(.bordered)
                        }
                        Button("Weiter") { next() }.buttonStyle(.borderedProminent)
                    }
                } else {
                    HStack {
                        Button("Weiß nicht") { input = ""; check(item) }.buttonStyle(.bordered)
                        Button("Prüfen") { check(item) }.buttonStyle(.borderedProminent)
                    }
                }
                Spacer()
            } else if started {
                Spacer()
                Image(systemName: "keyboard").font(.system(size: 50)).foregroundStyle(.green)
                Text("\(right) von \(total) richtig").font(.title.bold())
                Button("Fertig") { dismiss() }.buttonStyle(.borderedProminent)
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Eintippen")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !started else { return }
            started = true
            queue = items.shuffled()
            dir = direction.resolve()
            focused = true
        }
    }

    private func check(_ item: VocabItem) {
        let target = dir == .laDe ? item.de : item.headLa
        let ok = AnswerChecker.check(input, target: target, tolerant: tolerant)
        result = ok
        total += 1
        if ok { right += 1 }
        Haptics.result(ok)
        progress.record(item, knew: ok)
    }

    private func override(_ item: VocabItem) {
        progress.record(item, knew: true)
        right += 1
        result = true
    }

    private func next() {
        guard let item = queue.first else { return }
        queue.removeFirst()
        if result == false { queue.insert(item, at: min(4, queue.count)) }
        result = nil
        input = ""
        dir = direction.resolve()
        focused = true
    }
}

// MARK: - Zuordnen

struct MatchingView: View {
    let items: [VocabItem]
    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss

    @State private var remaining: [VocabItem] = []
    @State private var round: [VocabItem] = []
    @State private var left: [VocabItem] = []
    @State private var right: [VocabItem] = []
    @State private var selectedLeft: VocabItem? = nil
    @State private var wrongFlash: String? = nil
    @State private var mistakes: Set<String> = []
    @State private var seconds = 0
    @State private var done = false
    @State private var started = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            if done {
                Spacer()
                Image(systemName: "square.grid.2x2.fill").font(.system(size: 50)).foregroundStyle(.green)
                Text("Alle Paare gefunden!").font(.title.bold())
                Text("Zeit: \(seconds) s · Fehler: \(mistakes.count)")
                Button("Fertig") { dismiss() }.buttonStyle(.borderedProminent)
                Spacer()
            } else {
                HStack {
                    Label("\(seconds) s", systemImage: "timer").monospacedDigit()
                    Spacer()
                    Text("Noch \(remaining.count + round.count) Paare")
                }
                .font(.subheadline)
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 8) {
                        ForEach(left) { v in
                            tile(v.la, selected: selectedLeft == v, flash: false) { selectedLeft = v; Haptics.tap() }
                        }
                    }
                    VStack(spacing: 8) {
                        ForEach(right) { v in
                            tile(v.de, selected: false, flash: wrongFlash == v.id) { pick(v) }
                        }
                    }
                }
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Zuordnen")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in if started && !done { seconds += 1 } }
        .onAppear {
            guard !started else { return }
            started = true
            remaining = items.shuffled()
            nextRound()
        }
    }

    private func tile(_ text: String, selected: Bool, flash: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, minHeight: 54)
                .multilineTextAlignment(.center)
                .padding(4)
        }
        .buttonStyle(.bordered)
        .tint(flash ? .red : (selected ? .orange : .accentColor))
    }

    private func pick(_ v: VocabItem) {
        guard let l = selectedLeft else { return }
        if l.id == v.id {
            Haptics.result(true)
            progress.record(v, knew: !mistakes.contains(v.id))
            withAnimation {
                left.removeAll { $0.id == v.id }
                right.removeAll { $0.id == v.id }
                round.removeAll { $0.id == v.id }
            }
            selectedLeft = nil
            if round.isEmpty { nextRound() }
        } else {
            Haptics.result(false)
            mistakes.insert(l.id)
            wrongFlash = v.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { wrongFlash = nil }
        }
    }

    private func nextRound() {
        guard !remaining.isEmpty else { done = true; return }
        var batch: [VocabItem] = []
        var usedDe: Set<String> = []
        var rest: [VocabItem] = []
        for v in remaining {
            if batch.count < 6 && !usedDe.contains(v.de) {
                usedDe.insert(v.de)
                batch.append(v)
            } else {
                rest.append(v)
            }
        }
        remaining = rest
        round = batch
        left = batch.shuffled()
        right = batch.shuffled()
    }
}

// MARK: - Tabellen-Training

struct TableDrillView: View {
    let lessons: [Lesson]
    @Environment(ProgressStore.self) private var progress

    private var tables: [(String, Block)] {
        var out: [(String, Block)] = []
        for l in lessons {
            for s in l.grammar {
                for b in s.blocks where b.type == "table" {
                    out.append(("L\(l.number): \(s.title)", b))
                }
            }
        }
        return out
    }

    var body: some View {
        List {
            if tables.isEmpty { Text("Keine Tabellen in diesem Bereich.") }
            ForEach(Array(tables.enumerated()), id: \.offset) { i, t in
                NavigationLink {
                    HiddenTableView(title: t.0, block: t.1)
                } label: {
                    VStack(alignment: .leading) {
                        Text(t.0).font(.headline)
                        Text(t.1.headers?.filter { !$0.isEmpty }.joined(separator: " · ") ?? "")
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }
        }
        .navigationTitle("Tabellen lernen")
    }
}

struct HiddenTableView: View {
    let title: String
    let block: Block
    @Environment(ProgressStore.self) private var progress
    @State private var revealed: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Tippe auf ein Feld, um es aufzudecken. Sag die Form vorher laut!")
                    .font(.footnote).foregroundStyle(.secondary)
                ScrollView(.horizontal) {
                    Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                        GridRow {
                            ForEach(Array((block.headers ?? []).enumerated()), id: \.offset) { _, h in
                                Text(h).font(.caption.bold()).foregroundStyle(.secondary)
                            }
                        }
                        ForEach(Array((block.rows ?? []).enumerated()), id: \.offset) { r, row in
                            GridRow {
                                ForEach(Array(row.enumerated()), id: \.offset) { c, cell in
                                    cellView(cell, key: "\(r)-\(c)", isLabel: c == 0)
                                }
                            }
                        }
                    }
                    .padding(8)
                }
                HStack {
                    Button("Alle aufdecken") { revealAll() }.buttonStyle(.bordered)
                    Button("Neu verdecken") { revealed = [] }.buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func cellView(_ cell: String, key: String, isLabel: Bool) -> some View {
        if isLabel || revealed.contains(key) {
            Text(cell)
                .fontWeight(isLabel ? .semibold : .regular)
                .italic(!isLabel)
                .padding(6)
        } else {
            Button {
                revealed.insert(key)
                progress.countActivity()
                Haptics.tap()
            } label: {
                Text("?").frame(minWidth: 60, minHeight: 28)
            }
            .buttonStyle(.bordered)
        }
    }

    private func revealAll() {
        for (r, row) in (block.rows ?? []).enumerated() {
            for c in row.indices { revealed.insert("\(r)-\(c)") }
        }
    }
}
