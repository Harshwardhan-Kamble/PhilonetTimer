import SwiftUI

/// Home screen showing all saved articles with their accumulated reading time.
struct ArticleListView: View {
    @EnvironmentObject var articleStore: ArticleStore
    @EnvironmentObject var timeStore: TimeStore
    
    @State private var showingDebugPanel = false
    @State private var showingAddSheet = false
    @State private var manualURL = ""
    
    private var sortedArticles: [Article] {
        articleStore.articles.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    private var totalReadingTime: TimeInterval {
        articleStore.articles.reduce(0) { $0 + $1.readingTimeSeconds }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.06, blue: 0.12), Color(red: 0.10, green: 0.08, blue: 0.18)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()
                
                if articleStore.articles.isEmpty {
                    emptyState
                } else {
                    articleList
                }
            }
            .navigationTitle("Philonet")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingDebugPanel = true } label: {
                        Image(systemName: "ant").font(.system(size: 16, weight: .medium)).foregroundStyle(.purple)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22))
                            .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
            }
            .sheet(isPresented: $showingDebugPanel) {
                DebugPanelView().environmentObject(timeStore).environmentObject(articleStore)
            }
            .alert("Add Article URL", isPresented: $showingAddSheet) {
                TextField("https://example.com/article", text: $manualURL)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Add") { addManualURL() }
                Button("Cancel", role: .cancel) { manualURL = "" }
            } message: { Text("Paste an article URL to save it for later reading.") }
            .onAppear {
                articleStore.importPendingFromShareExtension()
                timeStore.reconcileOnLaunch(articles: &articleStore.articles)
                articleStore.save()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                statsHeader.padding(.horizontal).padding(.top, 8).padding(.bottom, 12)
                ForEach(sortedArticles) { article in
                    NavigationLink(destination: ReaderView(article: article)) {
                        ArticleRowView(article: article).padding(.horizontal).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation { timeStore.removeArticle(article.id); articleStore.remove(id: article.id) }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }
    
    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatCardView(icon: "books.vertical", value: "\(articleStore.articles.count)", label: "Articles", gradient: [.purple, .blue])
            StatCardView(icon: "clock", value: TimeFormatter.format(totalReadingTime), label: "Total Read", gradient: [.blue, .cyan])
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120).blur(radius: 20)
                Image(systemName: "book.closed").font(.system(size: 56, weight: .light))
                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            VStack(spacing: 8) {
                Text("No Articles Yet").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                Text("Share an article from Safari\nor tap + to add a URL").font(.system(size: 15)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Spacer()
        }
    }
    
    private func addManualURL() {
        let trimmed = manualURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let urlString = trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: urlString) else { manualURL = ""; return }
        articleStore.add(Article(url: url, title: url.host ?? urlString))
        manualURL = ""
    }
}

struct StatCardView: View {
    let icon: String; let value: String; let label: String; let gradient: [Color]
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 20, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
    }
}
