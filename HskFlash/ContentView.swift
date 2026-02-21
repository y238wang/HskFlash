import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    
    @Query(sort: \Flashcard.dueDate) private var allCards: [Flashcard]
    
    @State private var cardsForSession: [Flashcard]? = nil
    
    private var dueCards: [Flashcard] {
        let now = Date.now
        return allCards.filter { $0.id < lastSeenID && $0.dueDate <= now }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("HSK Flash")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 40)
                
                HStack(spacing: 15) {
                    StatusBadge(label: "Reviews", count: dueCards.count, color: .orange)
                    StatusBadge(label: "New", count: min(allCards.count - lastSeenID, 10), color: .blue)
                }
                .padding(.bottom, 20)

                Button {
                    prepareSession()
                } label: {
                    MenuButton(title: "Learn", icon: "book.fill", color: .blue)
                }

                // Placeholder for Settings
                Button {
                    print("Settings tapped")
                } label: {
                    MenuButton(title: "Settings", icon: "gearshape.fill", color: .gray)
                }

                Spacer()
            }
            .navigationDestination(item: $cardsForSession) { preparedCards in
                StudyView(cards: preparedCards)
            }
            .padding()
        }
    }
    
    private func prepareSession() {
        // Fetch exactly the next 10 cards starting after our lastSeenID
        let nextBatchStart = lastSeenID + 1
        let nextBatchEnd = lastSeenID + 10
        
        let descriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate<Flashcard> {
                $0.id >= nextBatchStart && $0.id <= nextBatchEnd
            },
            sortBy: [SortDescriptor(\.id)]
        )
        
        let newCards = (try? modelContext.fetch(descriptor)) ?? []
        
        // Update the lastSeenID so next time we get different cards
        if let lastID = newCards.last?.id {
            lastSeenID = lastID
        }
        
        // Mix Review cards + the 10 New cards
        cardsForSession = (dueCards + newCards).shuffled()
    }
}

struct StatusBadge: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.headline)
            Text(label)
                .font(.system(.caption2, design: .default).uppercaseSmallCaps()) // Fix is here
        }
        .frame(width: 80, height: 50)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// A reusable UI component for your buttons
struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color, lineWidth: 2)
        )
    }
}
