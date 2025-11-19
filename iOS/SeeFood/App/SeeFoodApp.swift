import SwiftUI
import Combine

@main
struct SeeFoodApp: App {
    @StateObject private var settingsService = SettingsService()
    @StateObject private var imageCacheService = ImageCacheService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsService)
                .environmentObject(imageCacheService)
                .onAppear {
                    setupApp()
                }
        }
    }

    private func setupApp() {
        // Configure global appearance
        configureAppearance()

        // Initialize services
        Task {
            await settingsService.loadSettings()
            await imageCacheService.cleanupOldCache()
        }
    }

    private func configureAppearance() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}