import Foundation
import Combine

class TimeStore: ObservableObject {
    @Published var mergeLog: [TimeMergeEntry] = []
    @Published private(set) var memoryTimes: [UUID: TimeInterval] = [:]
    private var lastFlushedValues: [UUID: TimeInterval] = [:]
    private let timesFileURL: URL?
    private let mergeLogFileURL: URL?
    
    init() {
        let container = AppGroupConstants.containerURL
        self.timesFileURL = container?.appendingPathComponent(AppGroupConstants.timesFileName)
        self.mergeLogFileURL = container?.appendingPathComponent(AppGroupConstants.mergeLogFileName)
        loadMergeLog()
    }
    
    init(containerOverride: URL) {
        self.timesFileURL = containerOverride.appendingPathComponent(AppGroupConstants.timesFileName)
        self.mergeLogFileURL = containerOverride.appendingPathComponent(AppGroupConstants.mergeLogFileName)
        loadMergeLog()
    }
    
    func incrementMemory(for articleID: UUID, by delta: TimeInterval = 1.0) {
        let current = memoryTimes[articleID] ?? 0
        memoryTimes[articleID] = current + delta
    }
    
    func setMemory(for articleID: UUID, value: TimeInterval) {
        memoryTimes[articleID] = value
    }
    
    func currentMemoryTime(for articleID: UUID) -> TimeInterval {
        memoryTimes[articleID] ?? 0
    }
    
    func loadFromDisk() -> [UUID: TimeInterval] {
        guard let url = timesFileURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONDecoder().decode([String: TimeInterval].self, from: data)
            var result: [UUID: TimeInterval] = [:]
            for (key, value) in dict {
                if let uuid = UUID(uuidString: key) {
                    result[uuid] = value
                }
            }
            return result
        } catch {
            print("[TimeStore] Failed to load from disk: \(error)")
            return [:]
        }
    }
    
    private func writeToDisk(times: [UUID: TimeInterval]) {
        guard let url = timesFileURL else { return }
        do {
            let stringDict = Dictionary(uniqueKeysWithValues: times.map { ($0.key.uuidString, $0.value) })
            let data = try JSONEncoder().encode(stringDict)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[TimeStore] Failed to write to disk: \(error)")
        }
    }
    
    func readDiskTime(for articleID: UUID) -> TimeInterval? {
        let diskTimes = loadFromDisk()
        return diskTimes[articleID]
    }
    
    func merge(memoryTime: TimeInterval?, diskTime: TimeInterval?) -> (resolved: TimeInterval, rule: MergeRule) {
        switch (memoryTime, diskTime) {
        case (nil, nil):
            return (0, .freshStart)
            
        case (let mem?, nil):
            return (mem, .memoryWins)
            
        case (nil, let disk?):
            return (disk, .diskWins)
            
        case (let mem?, let disk?):
            if mem == disk {
                return (mem, .deduplication)
            } else if mem > disk {
                return (mem, .memoryWins)
            } else {
                return (disk, .diskWins)
            }
        }
    }
    
    func flush(articleID: UUID, articleTitle: String) {
        let mem = memoryTimes[articleID]
        
        if let m = mem, m == lastFlushedValues[articleID] {
            return
        }
        
        let disk = readDiskTime(for: articleID)
        let (resolved, rule) = merge(memoryTime: mem, diskTime: disk)
        
        var allDisk = loadFromDisk()
        allDisk[articleID] = resolved
        writeToDisk(times: allDisk)
        
        memoryTimes[articleID] = resolved
        lastFlushedValues[articleID] = resolved
        
        let entry = TimeMergeEntry(
            articleID: articleID,
            articleTitle: articleTitle,
            memoryValue: mem,
            diskValue: disk,
            resolvedValue: resolved,
            rule: rule
        )
        mergeLog.insert(entry, at: 0)
        saveMergeLog()
    }
    
    func flushAll(articles: [Article]) {
        for article in articles {
            flush(articleID: article.id, articleTitle: article.title)
        }
    }
    
    func reconcileOnLaunch(articles: inout [Article]) {
        let diskTimes = loadFromDisk()
        
        for i in articles.indices {
            let articleID = articles[i].id
            let disk = diskTimes[articleID]
            let mem = memoryTimes[articleID]
            
            let (resolved, rule) = merge(memoryTime: mem, diskTime: disk)
            
            articles[i].readingTimeSeconds = resolved
            memoryTimes[articleID] = resolved
            lastFlushedValues[articleID] = resolved
            
            if disk != nil || mem != nil {
                let entry = TimeMergeEntry(
                    articleID: articleID,
                    articleTitle: articles[i].title,
                    memoryValue: mem,
                    diskValue: disk,
                    resolvedValue: resolved,
                    rule: rule
                )
                mergeLog.insert(entry, at: 0)
            }
        }
        saveMergeLog()
    }
    
    func resolvedTime(for articleID: UUID) -> TimeInterval {
        let mem = memoryTimes[articleID]
        let disk = readDiskTime(for: articleID)
        let (resolved, _) = merge(memoryTime: mem, diskTime: disk)
        return resolved
    }
    
    func simulateCrash() {
        memoryTimes.removeAll()
        lastFlushedValues.removeAll()
    }
    
    func clearMergeLog() {
        mergeLog.removeAll()
        saveMergeLog()
    }
    
    func forceFlush(articles: [Article]) {
        lastFlushedValues.removeAll()
        flushAll(articles: articles)
    }
    
    func diskTimesSnapshot() -> [UUID: TimeInterval] {
        loadFromDisk()
    }
    
    func removeArticle(_ articleID: UUID) {
        memoryTimes.removeValue(forKey: articleID)
        lastFlushedValues.removeValue(forKey: articleID)
        var allDisk = loadFromDisk()
        allDisk.removeValue(forKey: articleID)
        writeToDisk(times: allDisk)
    }
    
    private func saveMergeLog() {
        guard let url = mergeLogFileURL else { return }
        do {
            let data = try JSONEncoder().encode(mergeLog)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[TimeStore] Failed to save merge log: \(error)")
        }
    }
    
    private func loadMergeLog() {
        guard let url = mergeLogFileURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            mergeLog = try JSONDecoder().decode([TimeMergeEntry].self, from: data)
        } catch {
            print("[TimeStore] Failed to load merge log: \(error)")
        }
    }
}
