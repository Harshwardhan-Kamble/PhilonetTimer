import XCTest
@testable import PhilonetTimer

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
    
    func testFlushOnBackground_persistsMemoryToDisk() {
        let id = UUID()
        let articles = [Article.test(id: id, title: "BG Test")]
        
        for _ in 0..<30 {
            timeStore.incrementMemory(for: id, by: 1.0)
        }
        
        timeStore.flushAll(articles: articles)
        
        XCTAssertEqual(timeStore.readDiskTime(for: id), 30.0)
    }
    
    func testReconcileOnForeground_restoresFromDisk() {
        let id = UUID()
        
        timeStore.seedDisk(times: [id: 120.0])
        
        var articles = [Article.test(id: id, title: "Restored")]
        timeStore.reconcileOnLaunch(articles: &articles)
        
        XCTAssertEqual(articles[0].readingTimeSeconds, 120.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 120.0)
    }
    
    func testBackgroundTime_notDoubleCounted() {
        let id = UUID()
        let articles = [Article.test(id: id, title: "No Double Count")]
        
        timeStore.setMemory(for: id, value: 60.0)
        timeStore.flushAll(articles: articles)
        
        var mutableArticles = articles
        timeStore.reconcileOnLaunch(articles: &mutableArticles)
        
        XCTAssertEqual(mutableArticles[0].readingTimeSeconds, 60.0)
    }
    
    func testRapidBackgroundForeground_doesNotCorruptState() {
        let id = UUID()
        var articles = [Article.test(id: id, title: "Rapid Transition")]
        
        timeStore.setMemory(for: id, value: 50.0)
        
        for _ in 0..<20 {
            timeStore.flushAll(articles: articles)
            timeStore.reconcileOnLaunch(articles: &articles)
        }
        
        XCTAssertEqual(articles[0].readingTimeSeconds, 50.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 50.0)
        XCTAssertEqual(timeStore.readDiskTime(for: id), 50.0)
    }
    
    func testSession_continuesAfterBackground() {
        let id = UUID()
        let articles = [Article.test(id: id, title: "Continuity")]
        
        timeStore.setMemory(for: id, value: 30.0)
        
        timeStore.flushAll(articles: articles)
        
        var mutableArticles = articles
        timeStore.reconcileOnLaunch(articles: &mutableArticles)
        
        for _ in 0..<20 {
            timeStore.incrementMemory(for: id, by: 1.0)
        }
        
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 50.0)
    }
}
