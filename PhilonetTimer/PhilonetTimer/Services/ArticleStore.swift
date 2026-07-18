import Foundation
import Combine

class ArticleStore: ObservableObject {
    @Published var articles: [Article] = []
    private let fileURL: URL?
    
    init() {
        let container = AppGroupConstants.containerURL
        self.fileURL = container?.appendingPathComponent(AppGroupConstants.articlesFileName)
        load()
    }
    
    func add(_ article: Article) {
        guard !articles.contains(where: { $0.url == article.url }) else { return }
        articles.append(article)
        save()
    }
    
    func remove(at offsets: IndexSet) {
        articles.remove(atOffsets: offsets)
        save()
    }
    
    func remove(id: UUID) {
        articles.removeAll { $0.id == id }
        save()
    }
    
    func updateReadingTime(for articleID: UUID, seconds: TimeInterval) {
        if let index = articles.firstIndex(where: { $0.id == articleID }) {
            articles[index].readingTimeSeconds = seconds
            save()
        }
    }
    
    func importPendingFromShareExtension() {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName),
              let data = defaults.data(forKey: AppGroupConstants.pendingArticlesKey) else {
            return
        }
        
        do {
            let pending = try JSONDecoder().decode([SharedArticle].self, from: data)
            for shared in pending {
                let article = Article(from: shared)
                add(article)
            }
            defaults.removeObject(forKey: AppGroupConstants.pendingArticlesKey)
        } catch {
            print("[ArticleStore] Failed to decode pending articles: \(error)")
        }
    }
    
    func save() {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(articles)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[ArticleStore] Failed to save: \(error)")
        }
    }
    
    private func load() {
        guard let url = fileURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            articles = try JSONDecoder().decode([Article].self, from: data)
        } catch {
            print("[ArticleStore] Failed to load: \(error)")
        }
    }
}
