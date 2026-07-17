import Foundation

/// Central constants shared between the host app and Share Extension.
enum AppGroupConstants {
    /// The App Group identifier used for cross-target data sharing.
    static let suiteName = "group.com.philonet.timer"
    
    /// UserDefaults key for pending articles queued by the Share Extension.
    static let pendingArticlesKey = "pendingArticles"
    
    /// Filename for the on-disk article store (JSON).
    static let articlesFileName = "articles.json"
    
    /// Filename for the on-disk time store (JSON).
    static let timesFileName = "times.json"
    
    /// Filename for the merge log history (JSON).
    static let mergeLogFileName = "merge_log.json"
    
    /// Returns the shared container URL for the App Group.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }
}
