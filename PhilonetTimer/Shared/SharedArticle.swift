import Foundation

/// Minimal article representation written by the Share Extension and consumed by the host app.
/// Kept deliberately lightweight so the extension doesn't need to know about the full Article model.
struct SharedArticle: Codable, Equatable {
    let url: URL
    let title: String
    let dateShared: Date
}
