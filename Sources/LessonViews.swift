import SwiftUI

struct LessonListView: View {
    let lessons: [Lesson]

    var body: some View {
        List {
            if lessons.isEmpty {
                Text("Keine Lektionen gefunden.")
            }
            ForEach(lessons) { lesson in
                NavigationLink(value: lesson) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(lesson.number). \(lesson.title)").font(.headline)
                        Text("\(lesson.unit) · \(lesson.vocab.count) Vokabeln")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Lektionen")
        .navigationDestination(for: Lesson.self) { LessonDetailView(lesson: $0) }
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
            }
            .pickerStyle(.segmented)
            .padding()

            if tab == 0 { VocabListView(lesson: lesson) } else { GrammarView(lesson: lesson) }
        }
        .navigationTitle("Lektion \(lesson.number)")
        .navigationBarTitleDisplayMode(.inline)
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
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.la).font(.headline)
                if !item.forms.isEmpty {
                    Text(item.forms).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if box > 0 { Text("Box \(box)").font(.caption2).foregroundStyle(.tertiary) }
            }
            Text(hideGerman && !revealed ? "• • •" : item.de)
            if !item.note.isEmpty && (!hideGerman || revealed) {
                Text(item.note).font(.caption).foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { revealed.toggle() }
    }
}

struct GrammarView: View {
    let lesson: Lesson

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(lesson.grammar) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.title3.bold())
                        ForEach(section.blocks) { BlockView(block: $0) }
                    }
                }
            }
            .padding()
        }
    }
}

struct BlockView: View {
    let block: Block

    var body: some View {
        switch block.type {
        case "list":
            VStack(alignment: .leading, spacing: 4) {
                ForEach(block.items ?? [], id: \.self) { Text("• \($0)") }
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
