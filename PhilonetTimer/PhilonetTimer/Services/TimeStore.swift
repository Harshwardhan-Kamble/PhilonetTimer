import Foundation
import Combine

/// Dual-storage engine that maintains reading times in both memory and on disk,
/// with merge rules that prevent time from jumping backward or being double-counted.
///
/// ## Storage Layout
/// - **Memory**: `Dictionary<UUID, TimeInterval>` — updated every timer tick.
/// - **Disk**: `times.json` in the App Group container — flushed periodically and on background.
///
/// ## Merge Invariant
/// `resolvedTime = max(memoryTime ?? 0, diskTime ?? 0)` — time never goes backward.
class TimeStore: ObservableObject {
    
    // MARK: - Published State
    
    /// Audit log of all merge events, displayed in the Debug Panel.
    @Published var mergeLog: [TimeMergeEntry] = []
    
    /// Current in-memory time values per article.
    @Published private(set) var memoryTimes: [UUID: TimeInterval] = [:]
    
    // MARK: - Private State
    
    /// Tracks the last value flushed per article to avoid spurious no-op merges.
    private var lastFlushedValues: [UUID: TimeInterval] = [:]
    
    /// File URL for the on-disk times JSON.
    private let timesFileURL: URL?
    
    /// File URL for the persisted merge log.
    private let mergeLogFileURL: URL?
    
    // MARK: - Init
    
    init() {
        let container = AppGroupConstants.containerURL
        self.timesFileURL = container?.appendingPathComponent(AppGroupConstants.timesFileName)
        self.mergeLogFileURL = container?.appendingPathComponent(AppGroupConstants.mergeLogFileName)
        loadMergeLog()
    }
    
    // MARK: - Memory Layer
    
    /// Increments the in-memory time for an article. Called every timer tick.
    func incrementMemory(for articleID: UUID, by delta: TimeInterval = 1.0) {
        let current = memoryTimes[articleID] ?? 0
        memoryTimes[articleID] = current + delta
    }
    
    /// Sets the in-memory time directly (used during reconciliation).
    func setMemory(for articleID: UUID, value: TimeInterval) {
        memoryTimes[articleID] = value
    }
    
    /// Returns the current in-memory time for an article.
    func currentMemoryTime(for articleID: UUID) -> TimeInterval {
        memoryTimes[articleID] ?? 0
    }
    
    // MARK: - Disk Layer
    
    /// Reads all times from disk.
    func loadFromDisk() -> [UUID: TimeInterval] {
        guard let url = timesFileURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONDecoder().decode([String: TimeInterval].self, from: data)
            // Convert String keys back to UUIDs
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
    
    /// Writes a single article's resolved time to disk.
    private func writeToDisk(times: [UUID: TimeInterval]) {
        guard let url = timesFileURL else { return }
        do {
            // Convert UUID keys to String for JSON compatibility
            let stringDict = Dictionary(uniqueKeysWithValues: times.map { ($0.key.uuidString, $0.value) })
            let data = try JSONEncoder().encode(stringDict)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[TimeStore] Failed to write to disk: \(error)")
        }
    }
    
    /// Reads a single article's time from disk.
    func readDiskTime(for articleID: UUID) -> TimeInterval? {
        let diskTimes = loadFromDisk()
        return diskTimes[articleID]
    }
    
    // MARK: - Merge Engine
    
    /// Core merge function. Determines the resolved time and which rule was applied.
    ///
    /// ## Rules
    /// 1. Both nil → `(0, .freshStart)`
    /// 2. Disk nil → `(memory, .memoryWins)` — first save
    /// 3. Memory nil → `(disk, .diskWins)` — crash recovery
    /// 4. Equal → `(memory, .deduplication)` — no-op
    /// 5. Memory > Disk → `(memory, .memoryWins)` — normal progress
    /// 6. Disk > Memory → `(disk, .diskWins)` — never go backward
    ///
    /// In ALL cases the final assertion is: `resolved == max(memory ?? 0, disk ?? 0)`
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
    
    // MARK: - Flush Operations
    
    /// Flushes a single article's time from memory to disk, applying merge rules.
    func flush(articleID: UUID, articleTitle: String) {
        let mem = memoryTimes[articleID]
        
        // Deduplication guard: skip if nothing changed since last flush
        if let m = mem, m == lastFlushedValues[articleID] {
            return
        }
        
        let disk = readDiskTime(for: articleID)
        let (resolved, rule) = merge(memoryTime: mem, diskTime: disk)
        
        // Write resolved value to disk
        var allDisk = loadFromDisk()
        allDisk[articleID] = resolved
        writeToDisk(times: allDisk)
        
        // Update memory to resolved value (ensures consistency)
        memoryTimes[articleID] = resolved
        lastFlushedValues[articleID] = resolved
        
        // Log the merge event
        let entry = TimeMergeEntry(
            articleID: articleID,
            articleTitle: articleTitle,
            memoryValue: mem,
            diskValue: disk,
            resolvedValue: resolved,
            rule: rule
        )
        mergeLog.insert(entry, at: 0) // Newest first
        saveMergeLog()
    }
    
    /// Flushes all known articles to disk. Called when app backgrounds.
    func flushAll(articles: [Article]) {
        for article in articles {
            flush(articleID: article.id, articleTitle: article.title)
        }
    }
    
    // MARK: - Reconciliation (App Launch)
    
    /// Called on app launch to reconcile in-memory state with what's on disk.
    /// Updates each article's `readingTimeSeconds` to the merged value.
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
            
            // Only log if there was an actual merge situation (not fresh start with 0)
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
    
    /// Returns the authoritative resolved time for an article.
    func resolvedTime(for articleID: UUID) -> TimeInterval {
        let mem = memoryTimes[articleID]
        let disk = readDiskTime(for: articleID)
        let (resolved, _) = merge(memoryTime: mem, diskTime: disk)
        return resolved
    }
    
    // MARK: - Debug Actions
    
    /// Simulates a crash by clearing all in-memory times while leaving disk intact.
    func simulateCrash() {
        memoryTimes.removeAll()
        lastFlushedValues.removeAll()
    }
    
    /// Clears the merge audit log.
    func clearMergeLog() {
        mergeLog.removeAll()
        saveMergeLog()
    }
    
    /// Forces a flush of all articles, ignoring the deduplication guard.
    func forceFlush(articles: [Article]) {
        lastFlushedValues.removeAll() // Bypass dedup guard
        flushAll(articles: articles)
    }
    
    /// Returns a snapshot of current disk times for the debug panel.
    func diskTimesSnapshot() -> [UUID: TimeInterval] {
        loadFromDisk()
    }
    
    /// Removes time data for a specific article from both memory and disk.
    func removeArticle(_ articleID: UUID) {
        memoryTimes.removeValue(forKey: articleID)
        lastFlushedValues.removeValue(forKey: articleID)
        var allDisk = loadFromDisk()
        allDisk.removeValue(forKey: articleID)
        writeToDisk(times: allDisk)
    }
    
    // MARK: - Merge Log Persistence
    
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
