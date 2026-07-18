import Foundation
import Combine

class ReadingTimer: ObservableObject {
    @Published var elapsed: TimeInterval = 0
    @Published var isRunning: Bool = false
    private(set) var articleID: UUID?
    private weak var timeStore: TimeStore?
    private var timer: Timer?
    private let tickInterval: TimeInterval = 1.0
    
    func start(articleID: UUID, initialTime: TimeInterval, timeStore: TimeStore) {
        self.articleID = articleID
        self.timeStore = timeStore
        self.elapsed = initialTime
        
        if timeStore.currentMemoryTime(for: articleID) < initialTime {
            timeStore.setMemory(for: articleID, value: initialTime)
        }
        
        resume()
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    func resume() {
        guard articleID != nil, timer == nil else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    @discardableResult
    func stop() -> TimeInterval {
        pause()
        let finalElapsed = elapsed
        articleID = nil
        timeStore = nil
        return finalElapsed
    }
    
    private func tick() {
        elapsed += tickInterval
        if let id = articleID {
            timeStore?.incrementMemory(for: id, by: tickInterval)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
