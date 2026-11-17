import SwiftUI

@main
struct MediasInResApp: App {
    @State private var progress = ProgressStore()
    @State private var app = AppData()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(progress)
                .environment(app)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { LessonListView() }
                .tabItem { Label("Lektionen", systemImage: "book") }
            NavigationStack { PracticeHubView() }
                .tabItem { Label("Üben", systemImage: "brain.head.profile") }
            NavigationStack { SearchView() }
                .tabItem { Label("Suchen", systemImage: "magnifyingglass") }
            NavigationStack { StatsView() }
                .tabItem { Label("Statistik", systemImage: "chart.bar") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Einstellungen", systemImage: "gearshape") }
        }
    }
}
