import XCTest
@testable import PhilonetTimer

final class EdgeCaseTests: XCTestCase {
    
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
    
    func testZeroSecondSession_doesNotCorruptState() {
        let id = UUID()
        timeStore.incrementMemory(for: id, by: 0.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 0.0)
        
        let (resolved, rule) = timeStore.merge(memoryTime: 0.0, diskTime: 0.0)
        XCTAssertEqual(resolved, 0.0)
        XCTAssertEqual(rule, .deduplication)
    }
    
    func testMerge_negativeMemory_diskWins() {
        let (resolved, _) = timeStore.merge(memoryTime: -5.0, diskTime: 10.0)
        XCTAssertEqual(resolved, 10.0)
    }
    
    func testIncrementMemory_negativeDoesNotCrash() {
        let id = UUID()
        timeStore.incrementMemory(for: id, by: 10.0)
        timeStore.incrementMemory(for: id, by: -3.0)
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 7.0)
    }
    
    func testExtremelyLongSession() {
        let id = UUID()
        let twentyFourHours: TimeInterval = 86400.0
        timeStore.setMemory(for: id, value: twentyFourHours)
        timeStore.flush(articleID: id, articleTitle: "Marathon Reader")
        XCTAssertEqual(timeStore.readDiskTime(for: id), twentyFourHours)
    }
    
    func testMultipleArticles_independentTracking() {
        let ids = (0..<10).map { _ in UUID() }
        for (i, id) in ids.enumerated() {
            timeStore.setMemory(for: id, value: Double(i * 10))
        }
        for (i, id) in ids.enumerated() {
            XCTAssertEqual(timeStore.currentMemoryTime(for: id), Double(i * 10))
        }
    }
    
    func testMultipleArticles_flushAll_preservesAll() {
        let id1 = UUID(), id2 = UUID(), id3 = UUID()
        let articles = [
            Article.test(id: id1, title: "A1"),
            Article.test(id: id2, title: "A2"),
            Article.test(id: id3, title: "A3"),
        ]
        timeStore.setMemory(for: id1, value: 100)
        timeStore.setMemory(for: id2, value: 200)
        timeStore.setMemory(for: id3, value: 300)
        timeStore.flushAll(articles: articles)
        XCTAssertEqual(timeStore.readDiskTime(for: id1), 100)
        XCTAssertEqual(timeStore.readDiskTime(for: id2), 200)
        XCTAssertEqual(timeStore.readDiskTime(for: id3), 300)
    }
    
    func testRapidUpdates_doNotCorruptState() {
        let id = UUID()
        for i in 1...50 {
            timeStore.incrementMemory(for: id, by: 1.0)
            if i % 5 == 0 {
                timeStore.flush(articleID: id, articleTitle: "Rapid Test")
            }
        }
        XCTAssertEqual(timeStore.currentMemoryTime(for: id), 50.0)
        timeStore.flush(articleID: id, articleTitle: "Rapid Test")
        XCTAssertEqual(timeStore.readDiskTime(for: id), 50.0)
    }
    
    func testForceFlush_thenFlush_doesNotDoubleCount() {
        let id = UUID()
        let articles = [Article.test(id: id, title: "Dedup Test")]
        timeStore.setMemory(for: id, value: 60.0)
        timeStore.forceFlush(articles: articles)
        timeStore.flush(articleID: id, articleTitle: "Dedup Test")
        XCTAssertEqual(timeStore.readDiskTime(for: id), 60.0)
    }
}
