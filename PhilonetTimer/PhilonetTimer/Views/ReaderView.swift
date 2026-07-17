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
        ZStack(alignment: .top) {
            // Web content
            WebViewRepresentable(url: article.url)
                .ignoresSafeArea(edges: .bottom)
            
            // Floating timer HUD
            timerHUD
                .padding(.top, 8)
        }
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
    
    // MARK: - Timer HUD
    
    private var timerHUD: some View {
        HStack(spacing: 8) {
            // Pulsing dot indicator
            Circle()
                .fill(readingTimer.isRunning ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .shadow(color: readingTimer.isRunning ? .green.opacity(0.6) : .orange.opacity(0.6), radius: 4)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: readingTimer.isRunning)
            
            Image(systemName: "timer")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text(TimeFormatter.timerDisplay(readingTimer.elapsed))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.1), value: readingTimer.elapsed)
            
            Text(readingTimer.isRunning ? "Reading" : "Paused")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(readingTimer.isRunning ? .green : .orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
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
