import Foundation

enum DebugLogger {
    static let logPath = "/Users/michaelfuscoletti/Desktop/scroll-down-app/.cursor/debug.log"
    
    static func log(hypothesisId: String, location: String, message: String, data: [String: Any] = [:]) {
        let logEntry: [String: Any] = [
            "sessionId": "debug-session",
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: logEntry),
              let line = (String(data: jsonData, encoding: .utf8)! + "\n").data(using: .utf8) else { return }
        
        let url = URL(fileURLWithPath: logPath)
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(line)
            try? handle.close()
        } else {
            try? line.write(to: url)
        }
    }
}
