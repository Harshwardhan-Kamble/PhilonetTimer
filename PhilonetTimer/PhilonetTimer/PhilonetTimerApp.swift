import SwiftUI

/// Main entry point for the Philonet Reading Timer app.
/// Manages app lifecycle: imports pending articles from Share Extension,
/// reconciles memory/disk on foreground, and flushes on background.
@main
struct PhilonetTimerApp: App {
    @StateObject private var articleStore = ArticleStore()
    @StateObject private var timeStore = TimeStore()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ArticleListView()
                .environmentObject(articleStore)
                .environmentObject(timeStore)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // Import any articles shared while the app was closed
                articleStore.importPendingFromShareExtension()
                // Reconcile memory vs disk
                timeStore.reconcileOnLaunch(articles: &articleStore.articles)
                articleStore.save()
                
            case .background:
                // Flush all in-memory times to disk before suspending
                timeStore.flushAll(articles: articleStore.articles)
                articleStore.save()
                
            default:
                break
            }
        }
    }
}
