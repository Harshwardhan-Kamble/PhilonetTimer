import SwiftUI

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
                articleStore.importPendingFromShareExtension()
                timeStore.reconcileOnLaunch(articles: &articleStore.articles)
                articleStore.save()
                
            case .background:
                timeStore.flushAll(articles: articleStore.articles)
                articleStore.save()
                
            default:
                break
            }
        }
    }
}
