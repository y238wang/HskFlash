import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(filter: #Predicate<Flashcard> { $0.interval == 0 })
    private var newCards: [Flashcard]
    
    @Query(filter: #Predicate<Flashcard> { $0.interval > 0 })
    private var studiedCards: [Flashcard]
    
    @State private var cardsForSession: [Flashcard]? = nil
    
    private var dueCards: [Flashcard] {
        let now = Date.now
        return studiedCards.filter { $0.dueDate <= now }
    }

    var body: some View {
        NavigationStack { // This enables the "Push/Pop" navigation
            VStack(spacing: 20) {
                Text("HSK Flash")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 40)
                
                // Quick Status Stats
                HStack(spacing: 15) {
                    StatusBadge(label: "Reviews", count: dueCards.count, color: .orange)
                    StatusBadge(label: "New", count: min(newCards.count, 10), color: .blue)
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
        let tenNew = newCards
            .sorted { $0.level < $1.level }
            .prefix(10)
        cardsForSession = (dueCards + Array(tenNew)).shuffled()
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Flashcard.self, configurations: config)
    
    CardImporter.importCards(context: container.mainContext)
    
    return ContentView()
        .modelContainer(container)
}
