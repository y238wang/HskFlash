import Foundation
import SwiftData

struct StudyService {
    static func prepareSession(context: ModelContext, lastSeenID: Int) -> [Flashcard] {
        let limitID = lastSeenID + 20
        
        // Fetch Due
        let dayBoundary = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        let dueDescriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate<Flashcard> { card in
                card.id <= lastSeenID && card.dueDate <= dayBoundary
            }
        )
        let dueCards = (try? context.fetch(dueDescriptor)) ?? []
        
        // Fetch New
        let newDescriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate<Flashcard> { card in
                card.id > lastSeenID && card.id <= limitID
            },
            sortBy: [SortDescriptor(\.id)]
        )
        let newCards = (try? context.fetch(newDescriptor)) ?? []
        
        return dueCards + newCards
    }
}
