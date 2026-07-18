import SwiftUI

struct ArticleRowView: View {
    let article: Article
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            
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
                    Label(TimeFormatter.format(article.readingTimeSeconds), systemImage: "timer")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(article.readingTimeSeconds > 0 ? Color.blue : Color.secondary)
                    
                    Text(article.dateAdded, style: .relative)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
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
