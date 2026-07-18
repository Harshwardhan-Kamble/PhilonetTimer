import Foundation

enum AppGroupConstants {
    static let suiteName = "group.com.philonet.timer"
    static let pendingArticlesKey = "pendingArticles"
    static let articlesFileName = "articles.json"
    static let timesFileName = "times.json"
    static let mergeLogFileName = "merge_log.json"
    
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }
}
