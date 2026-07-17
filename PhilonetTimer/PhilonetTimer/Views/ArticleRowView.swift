import SwiftUI

/// A single row in the article list, displaying title, domain, reading time, and date.
struct ArticleRowView: View {
    let article: Article
    
    var body: some View {
        HStack(spacing: 14) {
            // Leading icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: "doc.richtext")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // Article details
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(article.domain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    // Reading time badge
                    Label(TimeFormatter.format(article.readingTimeSeconds), systemImage: "timer")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(article.readingTimeSeconds > 0 ? Color.blue : Color.secondary)
                    
                    // Date added
                    Text(article.dateAdded, style: .relative)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ArticleRowView(article: Article(
        url: URL(string: "https://example.com/article")!,
        title: "Understanding Swift Concurrency in Depth",
        readingTimeSeconds: 252
    ))
    .padding()
}
