import XCTest
@testable import PhilonetTimer

/// Tests for app lifecycle behavior: background/foreground transitions,
/// flush-on-background, reconcile-on-foreground.
final class LifecycleTests: XCTestCase {
    
    var timeStore: TestableTimeStore!
    
    override func setUp() {
        super.setUp()
        timeStore = TestableTimeStore()
    }
    
    override func tearDown() {
        timeStore.cleanup()
        timeStore = nil
        super.tearDown()
    }
    
    // MARK: - Background Flush
    
    func testFlushOnBackground_persistsMemoryToDisk() {
        let id = UUID()
        let articles = [Article.test(id: id, title: "BG Test")]
        
        // Simulate reading: tick 30 seconds
        for _ in 0..<30 {
            timeStore.incrementMemory(for: id, by: 1.0)
        }
        
        // Simulate app backgrounding
        timeStore.flushAll(articles: articles)
        
        XCTAssertEqual(timeStore.readDiskTime(for: id), 30.0)
    }
    
    // MARK: - Foreground Reconciliation
    
    func testReconcileOnForeground_restoresFromDisk() {
        let id = UUID()
        
        // Pre-existing disk data (from previous session)
        timeStore.seedDisk(times: [id: 120.0])
        
        // Simulate app launch (no memory)
        var articles = [Article.test(id: id, title: "Restored")]
        timeStore.reconcileOnLaunch(articles: &articles)
        
        XCTAssertEqual(articles[0].readingTimeSeconds, 120.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 120.0)
    }
    
    // MARK: - Background Time Not Double-Counted
    
    func testBackgroundTime_notDoubleCounted() {
        let id = UUID()
        let articles = [Article.test(id: id, title: "No Double Count")]
        
        // Session 1: read 60 seconds, then background
        timeStore.setMemory(for: id, value: 60.0)
        timeStore.flushAll(articles: articles)
        
        // Simulate "background period" — no ticks happen, time doesn't increase
        
        // Simulate foreground reconciliation
        var mutableArticles = articles
        timeStore.reconcileOnLaunch(articles: &mutableArticles)
        
        XCTAssertEqual(mutableArticles[0].readingTimeSeconds, 60.0,
            "Background time should not be double-counted")
    }
    
    // MARK: - Rapid Transitions
    
    func testRapidBackgroundForeground_doesNotCorruptState() {
        let id = UUID()
        var articles = [Article.test(id: id, title: "Rapid Transition")]
        
        // Initial reading
        timeStore.setMemory(for: id, value: 50.0)
        
        // Simulate 20 rapid bg/fg cycles
        for _ in 0..<20 {
            // Background: flush
            timeStore.flushAll(articles: articles)
            // Foreground: reconcile
            timeStore.reconcileOnLaunch(articles: &articles)
        }
        
        // Time should remain exactly 50, not grow or shrink
        XCTAssertEqual(articles[0].readingTimeSeconds, 50.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 50.0)
        XCTAssertEqual(timeStore.readDiskTime(for: id), 50.0)
    }
    
    // MARK: - Session Continuity Across Background
    
    func testSession_continuesAfterBackground() {
        let id = UUID()
        let articles = [Article.test(id: id, title: "Continuity")]
        
        // Read 30 seconds
        timeStore.setMemory(for: id, value: 30.0)
        
        // Background
        timeStore.flushAll(articles: articles)
        
        // Foreground - reconcile
        var mutableArticles = articles
        timeStore.reconcileOnLaunch(articles: &mutableArticles)
        
        // Continue reading 20 more seconds
        for _ in 0..<20 {
            timeStore.incrementMemory(for: id, by: 1.0)
        }
        
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 50.0,
            "Reading should continue from where it left off")
    }
}
