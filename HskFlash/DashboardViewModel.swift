import SwiftUI
import SwiftData

@Observable
class DashboardViewModel {
    var dueCount: Int = 0
    var newCount: Int = 0
    var totalCount: Int = 0
    
    @ObservationIgnored
    private var modelContext: ModelContext?

    func update(context: ModelContext, lastSeenID: Int, enabledLevels: Set<Int>) {
        self.modelContext = context
        let levelInt16s = enabledLevels.map { Int16($0) }
        
        let dayBoundary = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        let duePredicate = #Predicate<Flashcard> { card in
            levelInt16s.contains(card.level) && card.id <= lastSeenID && card.dueDate < dayBoundary
        }
        let dueDescriptor = FetchDescriptor<Flashcard>(predicate: duePredicate)
        self.dueCount = (try? context.fetchCount(dueDescriptor)) ?? 0
        
        let newPredicate = #Predicate<Flashcard> { card in
            levelInt16s.contains(card.level) && card.id > lastSeenID
        }
        let newDescriptor = FetchDescriptor<Flashcard>(predicate: newPredicate)
        self.newCount = (try? context.fetchCount(newDescriptor)) ?? 0
        
        let totalPredicate = #Predicate<Flashcard> { card in
            levelInt16s.contains(card.level)
        }
        let totalDescriptor = FetchDescriptor<Flashcard>(predicate: totalPredicate)
        self.totalCount = (try? context.fetchCount(totalDescriptor)) ?? 0
    }
}
