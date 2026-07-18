import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: UUID
    var url: URL
    var title: String
    var dateAdded: Date
    var readingTimeSeconds: TimeInterval
    
    var domain: String {
        url.host ?? url.absoluteString
    }
    
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
