import SwiftUI

struct DebugPanelView: View {
    @EnvironmentObject var timeStore: TimeStore
    @EnvironmentObject var articleStore: ArticleStore
    @Environment(\.dismiss) private var dismiss
    @State private var diskSnapshot: [UUID: TimeInterval] = [:]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Memory vs Disk")) {
                    if articleStore.articles.isEmpty {
                        Text("No articles").foregroundStyle(.secondary)
                    } else {
                        ForEach(articleStore.articles) { article in
                            let mem = timeStore.currentMemoryTime(for: article.id)
                            let disk = diskSnapshot[article.id]
                            let resolved = timeStore.resolvedTime(for: article.id)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(article.title)
                                    .font(.system(size: 15, weight: .semibold))
                                HStack {
                                    Text("Mem: \(TimeFormatter.debugFormat(mem))")
                                    Spacer()
                                    Text("Disk: \(TimeFormatter.debugFormat(disk))")
                                    Spacer()
                                    Text("Resolved: \(TimeFormatter.debugFormat(resolved))")
                                        .bold()
                                        .foregroundStyle(.blue)
                                }
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button {
                        timeStore.forceFlush(articles: articleStore.articles)
                        diskSnapshot = timeStore.diskTimesSnapshot()
                    } label: {
                        Label("Force Flush", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    Button(role: .destructive) {
                        timeStore.simulateCrash()
                        diskSnapshot = timeStore.diskTimesSnapshot()
                    } label: {
                        Label("Simulate Crash", systemImage: "bolt.slash")
                    }
                    
                    Button(role: .destructive) {
                        timeStore.clearMergeLog()
                    } label: {
                        Label("Clear Log", systemImage: "trash")
                    }
                }
                
                Section(header: Text("Merge Log (\(timeStore.mergeLog.count))")) {
                    if timeStore.mergeLog.isEmpty {
                        Text("No merge events").foregroundStyle(.secondary)
                    } else {
                        ForEach(timeStore.mergeLog) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.articleTitle)
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)
                                    Spacer()
                                    Text(entry.rule.displayName)
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.12))
                                        .cornerRadius(4)
                                        .foregroundStyle(.blue)
                                }
                                
                                HStack {
                                    Text("Mem: \(TimeFormatter.debugFormat(entry.memoryValue))")
                                    Spacer()
                                    Text("Disk: \(TimeFormatter.debugFormat(entry.diskValue))")
                                    Spacer()
                                    Text("→ \(TimeFormatter.debugFormat(entry.resolvedValue))")
                                        .bold()
                                }
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { diskSnapshot = timeStore.diskTimesSnapshot() }
        }
    }
}
