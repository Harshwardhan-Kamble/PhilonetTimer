import Foundation

struct SharedArticle: Codable, Equatable {
    let url: URL
    let title: String
    let dateShared: Date
}
