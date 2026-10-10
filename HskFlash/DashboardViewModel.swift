import SwiftUI
import SwiftData

@Observable
class DashboardViewModel {
    var dueCount: Int = 0
    var newCount: Int = 0
    var studiedCount: Int = 0
    var totalCount: Int = 0
     
    @ObservationIgnored
    private var modelContext: ModelContext?

    func update(context: ModelContext, enabledLevels: Set<Int>) {
        self.modelContext = context
         
        // Fetch all cards and filter in memory to completely bypass #Predicate macro limits
        let descriptor = FetchDescriptor<Flashcard>()
        let allCards = (try? context.fetch(descriptor)) ?? []
         
        let dayBoundary = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
         
        // Filter by enabled HSK levels
        let filteredCards = allCards.filter { enabledLevels.contains(Int($0.level)) }
         
        self.totalCount = filteredCards.count
        self.newCount = filteredCards.filter { $0.reviewCount == 0 }.count
        self.studiedCount = filteredCards.filter { $0.reviewCount > 0 }.count
        self.dueCount = filteredCards.filter { $0.reviewCount > 0 && $0.dueDate < dayBoundary }.count
    }
}
