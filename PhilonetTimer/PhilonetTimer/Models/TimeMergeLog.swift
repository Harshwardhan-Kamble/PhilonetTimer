import Foundation

enum MergeRule: String, Codable, CaseIterable {
    case memoryWins
    case diskWins
    case clampToMax
    case deduplication
    case freshStart
    
    var displayName: String {
        switch self {
        case .memoryWins:    return "Memory Wins"
        case .diskWins:      return "Disk Wins"
        case .clampToMax:    return "Clamp to Max"
        case .deduplication: return "Deduplicated"
        case .freshStart:    return "Fresh Start"
        }
    }
    
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
