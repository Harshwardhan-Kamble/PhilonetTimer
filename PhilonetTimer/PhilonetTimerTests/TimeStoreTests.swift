import XCTest
@testable import PhilonetTimer

final class TimeStoreTests: XCTestCase {
    
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
    
    func testIncrementMemory_startsFromZero() {
        let id = UUID()
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 0)
        
        timeStore.incrementMemory(for: id, by: 1.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 1.0)
    }
    
    func testIncrementMemory_accumulates() {
        let id = UUID()
        
        for _ in 0..<100 {
            timeStore.incrementMemory(for: id, by: 1.0)
        }
        
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 100.0)
    }
    
    func testSetMemory_overwritesPrevious() {
        let id = UUID()
        timeStore.incrementMemory(for: id, by: 50.0)
        timeStore.setMemory(for: id, value: 25.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 25.0)
    }
    
    func testMultipleArticles_trackedIndependently() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        
        timeStore.incrementMemory(for: id1, by: 10.0)
        timeStore.incrementMemory(for: id2, by: 20.0)
        timeStore.incrementMemory(for: id3, by: 30.0)
        
        XCTAssertEqual(timeStore.currentMemoryTime(for: id1), 10.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id2), 20.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id3), 30.0)
    }
    
    func testDisk_readEmpty_returnsEmpty() {
        let diskTimes = timeStore.loadFromDisk()
        XCTAssertTrue(diskTimes.isEmpty)
    }
    
    func testDisk_readAfterSeed() {
        let id = UUID()
        timeStore.seedDisk(times: [id: 42.0])
        
        let diskTime = timeStore.readDiskTime(for: id)
        XCTAssertEqual(diskTime, 42.0)
    }
    
    func testFlush_writesMemoryToDisk() {
        let id = UUID()
        let article = Article.test(id: id, title: "Flush Test")
        
        timeStore.incrementMemory(for: id, by: 60.0)
        timeStore.flush(articleID: id, articleTitle: article.title)
        
        let diskTime = timeStore.readDiskTime(for: id)
        XCTAssertEqual(diskTime, 60.0)
    }
    
    func testFlush_deduplication_skipsRedundantWrites() {
        let id = UUID()
        let article = Article.test(id: id, title: "Dedup Test")
        
        timeStore.incrementMemory(for: id, by: 30.0)
        timeStore.flush(articleID: id, articleTitle: article.title)
        
        let logCountAfterFirstFlush = timeStore.mergeLog.count
        
        timeStore.flush(articleID: id, articleTitle: article.title)
        
        XCTAssertEqual(timeStore.mergeLog.count, logCountAfterFirstFlush)
    }
    
    func testFlushAll_flushesMulitpleArticles() {
        let id1 = UUID()
        let id2 = UUID()
        let articles = [
            Article.test(id: id1, title: "Article 1"),
            Article.test(id: id2, title: "Article 2"),
        ]
        
        timeStore.incrementMemory(for: id1, by: 10.0)
        timeStore.incrementMemory(for: id2, by: 20.0)
        
        timeStore.flushAll(articles: articles)
        
        XCTAssertEqual(timeStore.readDiskTime(for: id1), 10.0)
        XCTAssertEqual(timeStore.readDiskTime(for: id2), 20.0)
    }
    
    func testReconcileOnLaunch_diskAhead_chooseDisk() {
        let id = UUID()
        timeStore.seedDisk(times: [id: 100.0])
        
        var articles = [Article.test(id: id, title: "Crashed Article")]
        timeStore.reconcileOnLaunch(articles: &articles)
        
        XCTAssertEqual(articles[0].readingTimeSeconds, 100.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 100.0)
    }
    
    func testReconcileOnLaunch_memoryAhead_chooseMemory() {
        let id = UUID()
        timeStore.setMemory(for: id, value: 200.0)
        timeStore.seedDisk(times: [id: 150.0])
        
        var articles = [Article.test(id: id, title: "Active Article")]
        timeStore.reconcileOnLaunch(articles: &articles)
        
        XCTAssertEqual(articles[0].readingTimeSeconds, 200.0)
    }
    
    func testReconcileOnLaunch_equalValues_unchanged() {
        let id = UUID()
        timeStore.setMemory(for: id, value: 75.0)
        timeStore.seedDisk(times: [id: 75.0])
        
        var articles = [Article.test(id: id, title: "Stable Article")]
        timeStore.reconcileOnLaunch(articles: &articles)
        
        XCTAssertEqual(articles[0].readingTimeSeconds, 75.0)
    }
    
    func testSimulateCrash_clearsMemory_preservesDisk() {
        let id = UUID()
        timeStore.incrementMemory(for: id, by: 50.0)
        timeStore.flush(articleID: id, articleTitle: "Pre-crash")
        
        timeStore.simulateCrash()
        
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 0)
        XCTAssertEqual(timeStore.readDiskTime(for: id), 50.0)
        
        var articles = [Article.test(id: id, title: "Recovered")]
        timeStore.reconcileOnLaunch(articles: &articles)
        XCTAssertEqual(articles[0].readingTimeSeconds, 50.0)
    }
    
    func testSimulateCrash_duringWrite_recoversFromDisk() {
        let id = UUID()
        
        timeStore.setMemory(for: id, value: 100.0)
        timeStore.flush(articleID: id, articleTitle: "Baseline")
        XCTAssertEqual(timeStore.readDiskTime(for: id), 100.0)
        
        timeStore.incrementMemory(for: id, by: 20.0)
        
        timeStore.simulateCrash()
        
        var articles = [Article.test(id: id, title: "Crash Recovery")]
        timeStore.reconcileOnLaunch(articles: &articles)
        
        XCTAssertEqual(articles[0].readingTimeSeconds, 100.0)
    }
    
    func testRemoveArticle_cleansBothMemoryAndDisk() {
        let id = UUID()
        timeStore.incrementMemory(for: id, by: 50.0)
        timeStore.flush(articleID: id, articleTitle: "To Remove")
        
        timeStore.removeArticle(id)
        
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 0)
        XCTAssertNil(timeStore.readDiskTime(for: id))
    }
    
    func testResolvedTime_choosesMax() {
        let id = UUID()
        timeStore.setMemory(for: id, value: 30.0)
        timeStore.seedDisk(times: [id: 50.0])
        
        XCTAssertEqual(timeStore.resolvedTime(for: id), 50.0)
    }
}
