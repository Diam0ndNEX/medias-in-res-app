import SwiftUI

@main
struct MediasInResApp: App {
    @State private var progress = ProgressStore()
    private let lessons = ContentStore.loadLessons()

    var body: some Scene {
        WindowGroup {
            RootView(lessons: lessons)
                .environment(progress)
        }
    }
}

struct RootView: View {
    let lessons: [Lesson]

    var body: some View {
        TabView {
            NavigationStack { LessonListView(lessons: lessons) }
                .tabItem { Label("Lektionen", systemImage: "book") }
            NavigationStack { TrainerSetupView(lessons: lessons) }
                .tabItem { Label("Üben", systemImage: "rectangle.on.rectangle.angled") }
            NavigationStack { ProgressView2(lessons: lessons) }
                .tabItem { Label("Fortschritt", systemImage: "chart.bar") }
        }
    }
}
