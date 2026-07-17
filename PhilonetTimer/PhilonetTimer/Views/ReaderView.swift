import SwiftUI

/// The reader view displays an article in a WKWebView with a floating timer HUD.
/// The timer starts on appear and pauses on disappear.
struct ReaderView: View {
    let article: Article
    
    @EnvironmentObject var timeStore: TimeStore
    @EnvironmentObject var articleStore: ArticleStore
    @StateObject private var readingTimer = ReadingTimer()
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        WebViewRepresentable(url: article.url)
            .ignoresSafeArea(edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(article.title)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Text(article.domain)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(readingTimer.isRunning ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(TimeFormatter.timerDisplay(readingTimer.elapsed))
                            .font(.system(.body, design: .monospaced))
                            .bold()
                    }
                }
            }
            .onAppear {
                startReading()
            }
            .onDisappear {
                stopReading()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    readingTimer.resume()
                case .inactive, .background:
                    readingTimer.pause()
                    timeStore.flush(articleID: article.id, articleTitle: article.title)
                    let resolved = timeStore.resolvedTime(for: article.id)
                    articleStore.updateReadingTime(for: article.id, seconds: resolved)
                @unknown default:
                    break
                }
            }
    }
    
    // MARK: - Reading Lifecycle
    
    private func startReading() {
        let initialTime = timeStore.resolvedTime(for: article.id)
        readingTimer.start(articleID: article.id, initialTime: initialTime, timeStore: timeStore)
    }
    
    private func stopReading() {
        readingTimer.pause()
        timeStore.flush(articleID: article.id, articleTitle: article.title)
        let resolved = timeStore.resolvedTime(for: article.id)
        articleStore.updateReadingTime(for: article.id, seconds: resolved)
    }
}
