import Foundation

/// Describes which merge rule was applied during a reconciliation event.
enum MergeRule: String, Codable, CaseIterable {
    /// Memory is ahead of disk — normal forward progress.
    case memoryWins
    /// Disk is ahead of memory — e.g. after a crash recovery.
    case diskWins
    /// Resolved to max(memory, disk) as a safety clamp.
    case clampToMax
    /// Values were identical; no real merge needed.
    case deduplication
    /// First-ever record, no prior data on either side.
    case freshStart
    
    /// Human-readable label for the debug panel.
    var displayName: String {
        switch self {
        case .memoryWins:    return "Memory Wins"
        case .diskWins:      return "Disk Wins"
        case .clampToMax:    return "Clamp to Max"
        case .deduplication: return "Deduplicated"
        case .freshStart:    return "Fresh Start"
        }
    }
    
    /// Color name (SF Symbol compatible) for badge rendering.
    var colorName: String {
        switch self {
        case .memoryWins:    return "green"
        case .diskWins:      return "orange"
        case .clampToMax:    return "red"
        case .deduplication: return "blue"
        case .freshStart:    return "gray"
        }
    }
}

/// A single entry in the merge audit log, capturing exactly what happened during reconciliation.
struct TimeMergeEntry: Identifiable, Codable {
    let id: UUID
    let articleID: UUID
    let articleTitle: String
    let timestamp: Date
    let memoryValue: TimeInterval?
    let diskValue: TimeInterval?
    let resolvedValue: TimeInterval
    let rule: MergeRule
    
    init(articleID: UUID, articleTitle: String, memoryValue: TimeInterval?, diskValue: TimeInterval?, resolvedValue: TimeInterval, rule: MergeRule) {
        self.id = UUID()
        self.articleID = articleID
        self.articleTitle = articleTitle
        self.timestamp = Date()
        self.memoryValue = memoryValue
        self.diskValue = diskValue
        self.resolvedValue = resolvedValue
        self.rule = rule
    }
}
