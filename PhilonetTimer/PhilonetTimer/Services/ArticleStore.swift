import Foundation
import Combine

/// Manages the article collection: CRUD operations, persistence, and import from Share Extension.
class ArticleStore: ObservableObject {
    
    /// The list of all saved articles.
    @Published var articles: [Article] = []
    
    /// File URL for on-disk article storage.
    private let fileURL: URL?
    
    // MARK: - Init
    
    init() {
        let container = AppGroupConstants.containerURL
        self.fileURL = container?.appendingPathComponent(AppGroupConstants.articlesFileName)
        load()
    }
    
    // MARK: - CRUD
    
    /// Adds a new article to the store.
    func add(_ article: Article) {
        // Avoid duplicates by URL
        guard !articles.contains(where: { $0.url == article.url }) else { return }
        articles.append(article)
        save()
    }
    
    /// Removes articles at the given index set.
    func remove(at offsets: IndexSet) {
        articles.remove(atOffsets: offsets)
        save()
    }
    
    /// Removes a specific article by ID.
    func remove(id: UUID) {
        articles.removeAll { $0.id == id }
        save()
    }
    
    /// Updates the reading time for a specific article.
    func updateReadingTime(for articleID: UUID, seconds: TimeInterval) {
        if let index = articles.firstIndex(where: { $0.id == articleID }) {
            articles[index].readingTimeSeconds = seconds
            save()
        }
    }
    
    // MARK: - Share Extension Import
    
    /// Imports any pending articles that were saved by the Share Extension.
    /// Clears the pending queue after import.
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
            // Clear the pending queue
            defaults.removeObject(forKey: AppGroupConstants.pendingArticlesKey)
        } catch {
            print("[ArticleStore] Failed to decode pending articles: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    /// Saves the article list to disk.
    func save() {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(articles)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[ArticleStore] Failed to save: \(error)")
        }
    }
    
    /// Loads the article list from disk.
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
