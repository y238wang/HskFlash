import Foundation
import SwiftData

@Model
class Flashcard {
    @Attribute(.unique) var id: Int
    
    var hanzi: String
    var pinyin: String
    var english: String
    var level: Int16
    
    // --- SRS CORE FIELDS ---
    var repetitions: Int = 0
    var easeFactor: Double = 2.5
    var interval: Int = 0
    var dueDate: Date = Date.now
    
    init(id: Int, hanzi: String, pinyin: String, english: String, level: Int16) {
        self.id = id
        self.hanzi = hanzi
        self.pinyin = pinyin
        self.english = english
        self.level = level
        self.dueDate = .now
    }
    
    /// Updates the card's schedule based on logic inspired by SM-2.
    /// - Parameter quality: 0 (Incorrect), 1 (Correct), 3 (Easy)
    func updateSRS(quality: Int) {
        if quality == 0 {
            repetitions = 0
            interval = 0
        } else {
            repetitions += 1
            
            // Calculate Ease Factor
            // Formula: EF' = EF + (0.1 - (3-q) * 0.08) - (3-q) * 0.02
            // Adjusted for a 0-3 scale:
            let adjustment = 0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02)
            easeFactor = max(1.3, easeFactor + adjustment)
            
            // 4. Calculate Interval (in days)
            if repetitions == 1 {
                interval = quality
            } else if repetitions == 2 {
                interval = 6 * quality
            } else {
                interval = Int(round(Double(interval) * easeFactor))
            }
        }
        
        // Calculate the next due date by adding 'interval' days to now
        if let nextDate = Calendar.current.date(byAdding: .day, value: interval, to: .now) {
            dueDate = nextDate
        }
    }
}
