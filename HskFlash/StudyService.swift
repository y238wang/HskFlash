import Foundation
import SwiftData

struct StudyService {
    static func prepareSession(context: ModelContext, lastSeenID: Int) -> [Flashcard] {
        let now = Date.now
        let limitID = lastSeenID + 10
        
        // Fetch Due
        let dueDescriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate<Flashcard> { card in
                card.id <= lastSeenID && card.dueDate <= now
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
