import SwiftUI

/// Debug panel showing memory vs disk values for each article and the full merge audit log.
struct DebugPanelView: View {
    @EnvironmentObject var timeStore: TimeStore
    @EnvironmentObject var articleStore: ArticleStore
    @Environment(\.dismiss) private var dismiss
    @State private var diskSnapshot: [UUID: TimeInterval] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        comparisonSection
                        actionsSection
                        mergeLogSection
                    }.padding()
                }
            }
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(.purple)
                }
            }
            .onAppear { diskSnapshot = timeStore.diskTimesSnapshot() }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Per-Article Comparison
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Memory vs Disk", icon: "memorychip")
            if articleStore.articles.isEmpty {
                Text("No articles").font(.system(size: 14)).foregroundStyle(.secondary).padding()
            } else {
                VStack(spacing: 1) {
                    // Header row
                    HStack {
                        Text("Article").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Memory").frame(width: 70)
                        Text("Disk").frame(width: 70)
                        Text("Resolved").frame(width: 70)
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.white.opacity(0.04))
                    
                    ForEach(articleStore.articles) { article in
                        let mem = timeStore.currentMemoryTime(for: article.id)
                        let disk = diskSnapshot[article.id]
                        let resolved = timeStore.resolvedTime(for: article.id)
                        
                        HStack {
                            Text(article.title).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                            Text(TimeFormatter.debugFormat(mem)).frame(width: 70)
                            Text(TimeFormatter.debugFormat(disk)).frame(width: 70)
                            Text(TimeFormatter.debugFormat(resolved)).frame(width: 70).foregroundStyle(.green)
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                    }
                }
                .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.06)))
            }
        }
    }
    
    // MARK: - Actions
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Actions", icon: "wrench.and.screwdriver")
            HStack(spacing: 12) {
                debugButton(title: "Force Flush", icon: "arrow.triangle.2.circlepath", color: .blue) {
                    timeStore.forceFlush(articles: articleStore.articles)
                    diskSnapshot = timeStore.diskTimesSnapshot()
                }
                debugButton(title: "Simulate Crash", icon: "bolt.slash", color: .orange) {
                    timeStore.simulateCrash()
                    diskSnapshot = timeStore.diskTimesSnapshot()
                }
                debugButton(title: "Clear Log", icon: "trash", color: .red) {
                    timeStore.clearMergeLog()
                }
            }
        }
    }
    
    // MARK: - Merge Log
    private var mergeLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Merge Log (\(timeStore.mergeLog.count))", icon: "list.bullet.rectangle")
            if timeStore.mergeLog.isEmpty {
                Text("No merge events recorded").font(.system(size: 14)).foregroundStyle(.secondary).padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(timeStore.mergeLog) { entry in
                        mergeEntryRow(entry)
                    }
                }
            }
        }
    }
    
    private func mergeEntryRow(_ entry: TimeMergeEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.articleTitle).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                Spacer()
                Text(entry.rule.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(ruleColor(entry.rule).opacity(0.2), in: Capsule())
                    .foregroundStyle(ruleColor(entry.rule))
            }
            HStack(spacing: 16) {
                Label("Mem: \(TimeFormatter.debugFormat(entry.memoryValue))", systemImage: "memorychip")
                Label("Disk: \(TimeFormatter.debugFormat(entry.diskValue))", systemImage: "internaldrive")
                Label("→ \(TimeFormatter.debugFormat(entry.resolvedValue))", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            }.font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
            Text(entry.timestamp, style: .relative).font(.system(size: 10)).foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.06)))
    }
    
    // MARK: - Helpers
    private func sectionHeader(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
    }
    
    private func debugButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(color)
                Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(color.opacity(0.3)))
        }
    }
    
    private func ruleColor(_ rule: MergeRule) -> Color {
        switch rule {
        case .memoryWins: return .green
        case .diskWins: return .orange
        case .clampToMax: return .red
        case .deduplication: return .blue
        case .freshStart: return .gray
        }
    }
}
