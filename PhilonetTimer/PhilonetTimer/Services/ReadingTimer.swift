import Foundation
import Combine

/// Manages a per-article reading timer that ticks every second.
/// The timer pauses when the app backgrounds and resumes when it returns.
class ReadingTimer: ObservableObject {
    
    /// Current elapsed reading time in seconds for this session.
    @Published var elapsed: TimeInterval = 0
    
    /// Whether the timer is currently running.
    @Published var isRunning: Bool = false
    
    /// The article ID this timer is tracking.
    private(set) var articleID: UUID?
    
    /// Reference to the TimeStore for incrementing memory on each tick.
    private weak var timeStore: TimeStore?
    
    /// The internal timer that fires every second.
    private var timer: Timer?
    
    /// Tick interval in seconds.
    private let tickInterval: TimeInterval = 1.0
    
    // MARK: - Public API
    
    /// Starts the timer for a given article, optionally resuming from a previous reading time.
    func start(articleID: UUID, initialTime: TimeInterval, timeStore: TimeStore) {
        self.articleID = articleID
        self.timeStore = timeStore
        self.elapsed = initialTime
        
        // Seed in-memory time if not already set
        if timeStore.currentMemoryTime(for: articleID) < initialTime {
            timeStore.setMemory(for: articleID, value: initialTime)
        }
        
        resume()
    }
    
    /// Pauses the timer (e.g. when app backgrounds or user navigates away).
    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    /// Resumes a paused timer.
    func resume() {
        guard articleID != nil, timer == nil else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // Ensure the timer fires even during scroll tracking
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// Stops the timer completely and returns the final elapsed time.
    @discardableResult
    func stop() -> TimeInterval {
        pause()
        let finalElapsed = elapsed
        articleID = nil
        timeStore = nil
        return finalElapsed
    }
    
    // MARK: - Private
    
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
