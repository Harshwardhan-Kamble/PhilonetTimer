import Foundation

/// Represents a saved article with its accumulated reading time.
struct Article: Identifiable, Codable, Equatable {
    let id: UUID
    var url: URL
    var title: String
    var dateAdded: Date
    /// Authoritative merged reading time in seconds.
    var readingTimeSeconds: TimeInterval
    
    /// Convenience: extracts the host/domain from the URL.
    var domain: String {
        url.host ?? url.absoluteString
    }
    
    /// Creates a new Article from a SharedArticle received via the Share Extension.
    init(from shared: SharedArticle) {
        self.id = UUID()
        self.url = shared.url
        self.title = shared.title.isEmpty ? shared.url.absoluteString : shared.title
        self.dateAdded = shared.dateShared
        self.readingTimeSeconds = 0
    }
    
    init(id: UUID = UUID(), url: URL, title: String, dateAdded: Date = Date(), readingTimeSeconds: TimeInterval = 0) {
        self.id = id
        self.url = url
        self.title = title
        self.dateAdded = dateAdded
        self.readingTimeSeconds = readingTimeSeconds
    }
}
