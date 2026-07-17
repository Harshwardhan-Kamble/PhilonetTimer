import Foundation

/// Utility for formatting TimeInterval values into human-readable reading-time strings.
enum TimeFormatter {
    
    /// Formats seconds into a compact string like "4m 12s" or "1h 23m".
    /// - Parameter seconds: The time interval in seconds.
    /// - Returns: A formatted string.
    static func format(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(0, seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
    
    /// Formats seconds into a precise timer display like "04:12" or "1:23:45".
    /// Used for the live reading timer HUD.
    static func timerDisplay(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(0, seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    /// Formats a TimeInterval with full decimal precision for the debug panel.
    static func debugFormat(_ seconds: TimeInterval?) -> String {
        guard let seconds = seconds else { return "nil" }
        return String(format: "%.1fs", seconds)
    }
}
