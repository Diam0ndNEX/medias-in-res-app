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
    @Environment(AppData.self) private var app
    @Environment(ProgressStore.self) private var progress
    @AppStorage("onboarded") private var onboarded = false

    var body: some View {
        TabView {
            NavigationStack { LessonListView() }
                .tabItem { Label("Lektionen", systemImage: "book") }
            NavigationStack { PracticeHubView() }
                .tabItem { Label("Üben", systemImage: "brain.head.profile") }
                .badge(progress.dueCount(in: app.allVocab))
            NavigationStack { SearchView() }
                .tabItem { Label("Suchen", systemImage: "magnifyingglass") }
            NavigationStack { StatsView() }
                .tabItem { Label("Statistik", systemImage: "chart.bar") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Einstellungen", systemImage: "gearshape") }
        }
        .sheet(isPresented: Binding(get: { !onboarded }, set: { if !$0 { onboarded = true } })) {
            OnboardingView()
        }
    }
}
