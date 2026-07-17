import XCTest
@testable import PhilonetTimer

/// Tests for the core merge engine in TimeStore.
/// Validates all 6 merge rules and invariants.
final class MergeEngineTests: XCTestCase {
    
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
    
    // MARK: - Rule 1: Both nil → freshStart
    
    func testMerge_bothNil_returnsFreshStart() {
        let (resolved, rule) = timeStore.merge(memoryTime: nil, diskTime: nil)
        XCTAssertEqual(resolved, 0, "Both nil should resolve to 0")
        XCTAssertEqual(rule, .freshStart)
    }
    
    // MARK: - Rule 2: Disk nil → memoryWins
    
    func testMerge_diskNil_memoryWins() {
        let (resolved, rule) = timeStore.merge(memoryTime: 42.0, diskTime: nil)
        XCTAssertEqual(resolved, 42.0)
        XCTAssertEqual(rule, .memoryWins)
    }
    
    // MARK: - Rule 3: Memory nil → diskWins
    
    func testMerge_memoryNil_diskWins() {
        let (resolved, rule) = timeStore.merge(memoryTime: nil, diskTime: 100.0)
        XCTAssertEqual(resolved, 100.0)
        XCTAssertEqual(rule, .diskWins)
    }
    
    // MARK: - Rule 4: Equal → deduplication
    
    func testMerge_equalValues_deduplication() {
        let (resolved, rule) = timeStore.merge(memoryTime: 50.0, diskTime: 50.0)
        XCTAssertEqual(resolved, 50.0)
        XCTAssertEqual(rule, .deduplication)
    }
    
    // MARK: - Rule 5: Memory > Disk → memoryWins
    
    func testMerge_memoryGreaterThanDisk_memoryWins() {
        let (resolved, rule) = timeStore.merge(memoryTime: 120.0, diskTime: 100.0)
        XCTAssertEqual(resolved, 120.0)
        XCTAssertEqual(rule, .memoryWins)
    }
    
    // MARK: - Rule 6: Disk > Memory → diskWins (never go backward)
    
    func testMerge_diskGreaterThanMemory_diskWins() {
        let (resolved, rule) = timeStore.merge(memoryTime: 80.0, diskTime: 150.0)
        XCTAssertEqual(resolved, 150.0)
        XCTAssertEqual(rule, .diskWins)
    }
    
    // MARK: - Merge Invariant: resolved == max(memory ?? 0, disk ?? 0)
    
    func testMerge_invariant_resolvedIsAlwaysMax() {
        let testCases: [(TimeInterval?, TimeInterval?)] = [
            (nil, nil),
            (10, nil),
            (nil, 20),
            (30, 30),
            (50, 40),
            (40, 50),
            (0, 0),
            (0, 100),
            (100, 0),
            (0.001, 0.0001),
        ]
        
        for (mem, disk) in testCases {
            let (resolved, _) = timeStore.merge(memoryTime: mem, diskTime: disk)
            let expected = max(mem ?? 0, disk ?? 0)
            XCTAssertEqual(resolved, expected, "merge(\(String(describing: mem)), \(String(describing: disk))) should be \(expected)")
        }
    }
    
    // MARK: - Idempotency
    
    func testMerge_isIdempotent() {
        // Merging the same values repeatedly should always produce the same result
        let mem: TimeInterval = 75.0
        let disk: TimeInterval = 60.0
        
        let (resolved1, rule1) = timeStore.merge(memoryTime: mem, diskTime: disk)
        let (resolved2, rule2) = timeStore.merge(memoryTime: resolved1, diskTime: disk)
        let (resolved3, rule3) = timeStore.merge(memoryTime: resolved2, diskTime: resolved2)
        
        XCTAssertEqual(resolved1, 75.0)
        XCTAssertEqual(resolved2, 75.0)
        XCTAssertEqual(resolved3, 75.0)
        XCTAssertEqual(rule1, .memoryWins)
        XCTAssertEqual(rule2, .memoryWins)
        XCTAssertEqual(rule3, .deduplication)
    }
    
    // MARK: - Time Never Goes Backward
    
    func testMerge_timeNeverDecreases() {
        var previousResolved: TimeInterval = 0
        
        // Simulate a sequence of merge operations with varying values
        let sequence: [(TimeInterval?, TimeInterval?)] = [
            (0, nil),
            (10, nil),
            (20, 10),
            (15, 20),    // Memory went backward (crash), disk should win
            (25, 20),    // Normal progress
            (25, 25),    // Dedup
            (nil, 25),   // Memory lost (crash recovery)
        ]
        
        for (mem, disk) in sequence {
            let (resolved, _) = timeStore.merge(memoryTime: mem, diskTime: disk)
            XCTAssertGreaterThanOrEqual(resolved, previousResolved,
                "Time went backward: \(resolved) < \(previousResolved)")
            previousResolved = resolved
        }
    }
}
