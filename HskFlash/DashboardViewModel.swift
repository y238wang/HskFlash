import SwiftUI
import SwiftData

@Observable
class DashboardViewModel {
    var dueCount: Int = 0
    var newCount: Int = 0
    var totalCount: Int = 0
    
    @ObservationIgnored
    private var modelContext: ModelContext?

    func update(context: ModelContext, lastSeenID: Int) {
        self.modelContext = context
        
        let now = Date.now
        let duePredicate = #Predicate<Flashcard> { $0.id < lastSeenID && $0.dueDate <= now }
        let dueDescriptor = FetchDescriptor<Flashcard>(predicate: duePredicate)
        self.dueCount = (try? context.fetchCount(dueDescriptor)) ?? 0
        
        let newPredicate = #Predicate<Flashcard> { $0.id > lastSeenID }
        let newDescriptor = FetchDescriptor<Flashcard>(predicate: newPredicate)
        self.newCount = (try? context.fetchCount(newDescriptor)) ?? 0
        
        let totalDescriptor = FetchDescriptor<Flashcard>()
        self.totalCount = (try? context.fetchCount(totalDescriptor)) ?? 0
    }
}
