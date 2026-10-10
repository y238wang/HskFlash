import Foundation
import SwiftData

struct StudyService {
    static func prepareSession(context: ModelContext, enabledLevels: Set<Int>) -> [Flashcard] {
        let levelInt16s = enabledLevels.map { Int16($0) }
        let dayBoundary = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        
        // 1. Fetch Due Cards: Belong to enabled levels, have been studied before, and are due today or earlier.
        let dueDescriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate<Flashcard> { card in
                levelInt16s.contains(card.level) && card.reviewCount > 0 && card.dueDate <= dayBoundary
            },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        let dueCards = (try? context.fetch(dueDescriptor)) ?? []
        
        // 2. Fetch New Cards: Belong to enabled levels and have never been studied yet (reviewCount == 0).
        var newDescriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate<Flashcard> { card in
                levelInt16s.contains(card.level) && card.reviewCount == 0
            },
            sortBy: [SortDescriptor(\.id)]
        )
        newDescriptor.fetchLimit = 20
        let newCards = (try? context.fetch(newDescriptor)) ?? []
        
        return dueCards + newCards
    }
}
