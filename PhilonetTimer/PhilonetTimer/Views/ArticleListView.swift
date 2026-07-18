import SwiftUI

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
            Group {
                if articleStore.articles.isEmpty {
                    emptyState
                } else {
                    articleList
                }
            }
            .navigationTitle("Philonet")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingDebugPanel = true } label: {
                        Image(systemName: "ant")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingDebugPanel) {
                DebugPanelView()
                    .environmentObject(timeStore)
                    .environmentObject(articleStore)
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("Article Information"), footer: Text("Paste an article URL to save it for later reading.")) {
                            TextField("URL", text: $manualURL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                        }
                    }
                    .navigationTitle("Add Article")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddSheet = false
                                manualURL = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                addManualURL()
                                showingAddSheet = false
                            }
                            .disabled(manualURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .onAppear {
                articleStore.importPendingFromShareExtension()
                timeStore.reconcileOnLaunch(articles: &articleStore.articles)
                articleStore.save()
            }
        }
    }
    
    private var articleList: some View {
        List {
            Section(header: Text("Stats")) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(articleStore.articles.count)")
                            .font(.title2)
                            .bold()
                        Text("Articles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    VStack(alignment: .trailing) {
                        Text(TimeFormatter.format(totalReadingTime))
                            .font(.title2)
                            .bold()
                        Text("Total Read")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Articles")) {
                ForEach(sortedArticles) { article in
                    NavigationLink(destination: ReaderView(article: article)) {
                        ArticleRowView(article: article)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                timeStore.removeArticle(article.id)
                                articleStore.remove(id: article.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Articles Yet", systemImage: "book.closed")
        } description: {
            Text("Share an article from Safari or tap the + button to add a URL manually.")
        } actions: {
            Button("Add URL") {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
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
