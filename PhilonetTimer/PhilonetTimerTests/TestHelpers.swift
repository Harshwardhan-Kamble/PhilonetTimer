import Foundation
import XCTest
@testable import PhilonetTimer

class TestableTimeStore: TimeStore {
    let tempDirectory: URL
    
    init(tempDirectory: URL? = nil) {
        if let dir = tempDirectory {
            self.tempDirectory = dir
        } else {
            self.tempDirectory = FileManager.default.temporaryDirectory
                .appendingPathComponent("PhilonetTimerTests-\(UUID().uuidString)")
        }
        try? FileManager.default.createDirectory(at: self.tempDirectory, withIntermediateDirectories: true)
        super.init(containerOverride: self.tempDirectory)
    }
    
    func cleanup() {
        try? FileManager.default.removeItem(at: tempDirectory)
    }
    
    func seedDisk(times: [UUID: TimeInterval]) {
        let stringDict = Dictionary(uniqueKeysWithValues: times.map { ($0.key.uuidString, $0.value) })
        let data = try! JSONEncoder().encode(stringDict)
        let url = tempDirectory.appendingPathComponent(AppGroupConstants.timesFileName)
        try! data.write(to: url, options: .atomic)
    }
}

extension Article {
    static func test(
        id: UUID = UUID(),
        title: String = "Test Article",
        url: String = "https://example.com/article",
        readingTimeSeconds: TimeInterval = 0
    ) -> Article {
        Article(
            id: id,
            url: URL(string: url)!,
            title: title,
            readingTimeSeconds: readingTimeSeconds
        )
    }
}
