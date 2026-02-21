import SwiftUI
import SwiftData

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    
    // We sort by ID so the list follows the HSK curriculum order
    @Query(sort: \Flashcard.id) private var allCards: [Flashcard]
    
    var body: some View {
        NavigationStack {
            List(allCards) { card in
                CardRow(card: card, lastSeenID: lastSeenID)
            }
            .navigationTitle("Dictionary")
            // Optional: Add a search bar later!
        }
    }
}

struct CardRow: View {
    let card: Flashcard
    let lastSeenID: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(card.hanzi)
                    .font(.title3.bold())
                Text(card.pinyin)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("HSK \(card.level)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                
                statusText
            }
        }
        .padding(.vertical, 4)
    }
    
    // This logic determines if it's "New" or shows the "Due" date
    @ViewBuilder
    private var statusText: some View {
        if card.id > lastSeenID {
            Text("New")
                .font(.caption2)
                .foregroundStyle(.blue)
        } else {
            Text(dueFormatted)
                .font(.caption2)
                .foregroundStyle(isOverdue ? .orange : .secondary)
        }
    }

    private var isOverdue: Bool {
        card.dueDate <= .now
    }

    private var dueFormatted: String {
        let calendar = Calendar.current
        
        // 1. Strip time components by getting the start of each day
        let startOfNow = calendar.startOfDay(for: .now)
        let startOfDue = calendar.startOfDay(for: card.dueDate)
        
        // 2. Calculate the difference in whole days
        let components = calendar.dateComponents([.day], from: startOfNow, to: startOfDue)
        let days = components.day ?? 0
        
        if days < 0 {
            return "\(-days)d ago"
        } else if days == 0 {
            return "Today"
        } else {
            return "in \(days)d"
        }
    }
}

#Preview {
    // 1. Create the schema and in-memory container
    let schema = Schema([Flashcard.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = container.mainContext
    
    // 2. Seed various card types
    // Overdue Card
    let card1 = Flashcard(id: 1, hanzi: "你好", pinyin: "nǐ hǎo", english: "Hello", level: 1)
    card1.dueDate = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
    
    // Due Today Card
    let card2 = Flashcard(id: 2, hanzi: "谢谢", pinyin: "xièxie", english: "Thanks", level: 1)
    card2.dueDate = .now
    
    // Future Due Card
    let card3 = Flashcard(id: 3, hanzi: "再见", pinyin: "zàijiàn", english: "Goodbye", level: 1)
    card3.dueDate = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
    
    // New Card (ID > lastSeenID)
    let card4 = Flashcard(id: 10, hanzi: "中国", pinyin: "Zhōngguó", english: "China", level: 2)
    
    [card1, card2, card3, card4].forEach { context.insert($0) }
    
    // 3. Setup AppStorage for the preview environment
    UserDefaults.standard.set(5, forKey: "lastSeenID")
    
    return CardListView()
        .modelContainer(container)
}
