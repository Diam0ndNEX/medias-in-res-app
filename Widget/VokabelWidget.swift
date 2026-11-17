import SwiftUI
import WidgetKit

struct WordEntry: TimelineEntry {
    let date: Date
    let la: String
    let forms: String
    let de: String
    let lesson: Int
}

struct WordProvider: TimelineProvider {
    static let sample = WordEntry(date: Date(), la: "amicus m.", forms: "amici", de: "Freund", lesson: 1)

    static func loadVocab() -> [VocabItem] {
        let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        var lessons: [Lesson] = []
        for url in urls where url.lastPathComponent.hasPrefix("lektion-") {
            if let data = try? Data(contentsOf: url), var l = try? JSONDecoder().decode(Lesson.self, from: data) {
                let n = l.number
                l.vocab = l.vocab.map { var v = $0; v.lesson = n; return v }
                lessons.append(l)
            }
        }
        return lessons.sorted { $0.number < $1.number }.flatMap { $0.vocab }
    }

    static func entry(for date: Date) -> WordEntry {
        guard let w = DailyWord.pick(from: loadVocab(), date: date) else { return sample }
        return WordEntry(date: date, la: w.la, forms: w.forms, de: w.de, lesson: w.lesson)
    }

    func placeholder(in context: Context) -> WordEntry { Self.sample }

    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) {
        completion(Self.entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let now = Date()
        let tomorrow = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400 + 60)
        completion(Timeline(entries: [Self.entry(for: now)], policy: .after(tomorrow)))
    }
}

struct VokabelWidgetView: View {
    let entry: WordEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text(entry.la).font(.headline).widgetAccentable()
                Text(entry.de).font(.caption).lineLimit(2)
            }
        case .accessoryInline:
            Text("\(entry.la) = \(entry.de)")
        default:
            VStack(alignment: .leading, spacing: 4) {
                Text("VOKABEL DES TAGES").font(.system(size: 9, weight: .bold)).foregroundStyle(.orange)
                Spacer(minLength: 0)
                Text(entry.la).font(family == .systemSmall ? .headline : .title2).bold()
                    .minimumScaleFactor(0.6).lineLimit(2)
                if !entry.forms.isEmpty && family != .systemSmall {
                    Text(entry.forms).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Text(entry.de).font(family == .systemSmall ? .caption : .body)
                    .lineLimit(3).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text("Lektion \(entry.lesson)").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@main
struct VokabelWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VokabelDesTages", provider: WordProvider()) { entry in
            VokabelWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Vokabel des Tages")
        .description("Jeden Tag ein Wort aus Medias in Res.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}
