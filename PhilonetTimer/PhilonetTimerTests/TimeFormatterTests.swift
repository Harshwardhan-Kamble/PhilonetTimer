import XCTest
@testable import PhilonetTimer

/// Tests for the TimeFormatter utility.
final class TimeFormatterTests: XCTestCase {
    
    // MARK: - Compact Format
    
    func testFormat_zeroSeconds() {
        XCTAssertEqual(TimeFormatter.format(0), "0s")
    }
    
    func testFormat_secondsOnly() {
        XCTAssertEqual(TimeFormatter.format(45), "45s")
    }
    
    func testFormat_minutesAndSeconds() {
        XCTAssertEqual(TimeFormatter.format(125), "2m 5s")
    }
    
    func testFormat_hoursAndMinutes() {
        XCTAssertEqual(TimeFormatter.format(3661), "1h 1m")
    }
    
    func testFormat_negativeClampedToZero() {
        XCTAssertEqual(TimeFormatter.format(-10), "0s")
    }
    
    // MARK: - Timer Display
    
    func testTimerDisplay_zeroSeconds() {
        XCTAssertEqual(TimeFormatter.timerDisplay(0), "00:00")
    }
    
    func testTimerDisplay_minutesAndSeconds() {
        XCTAssertEqual(TimeFormatter.timerDisplay(125), "02:05")
    }
    
    func testTimerDisplay_hoursFormat() {
        XCTAssertEqual(TimeFormatter.timerDisplay(3661), "1:01:01")
    }
    
    // MARK: - Debug Format
    
    func testDebugFormat_nil() {
        XCTAssertEqual(TimeFormatter.debugFormat(nil), "nil")
    }
    
    func testDebugFormat_value() {
        XCTAssertEqual(TimeFormatter.debugFormat(42.5), "42.5s")
    }
}
