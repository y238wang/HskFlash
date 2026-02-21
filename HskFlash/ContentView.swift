import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("hasImportedCards") private var hasImportedCards: Bool = false
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    
    @Query(sort: \Flashcard.dueDate) private var allCards: [Flashcard]
    
    @State private var cardsForSession: [Flashcard]? = nil
    @State private var isShowingSettings = false
    @State private var isImporting = false
    @State private var importProgress: Double = 0.0
    
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
                    isShowingSettings = true
                } label: {
                    MenuButton(title: "Settings", icon: "gearshape.fill", color: .gray)
                }

                Spacer()
            }
            .padding()
            .overlay {
                if isImporting {
                    ZStack {
                        Color(uiColor: .systemBackground)
                            .ignoresSafeArea()
                        VStack(spacing: 20) {
                            ProgressView(value: importProgress, total: 1.0)
                                .progressViewStyle(.linear)
                                .padding(.horizontal, 40)
                            Text("Importing HSK Dictionary...")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .navigationDestination(item: $cardsForSession) { preparedCards in
                StudyView(cards: preparedCards)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
        .onAppear {
            triggerImportIfNeeded()
        }
        .onChange(of: hasImportedCards) { oldValue, newValue in
            if newValue == false {
                triggerImportIfNeeded()
            }
        }
    }
    
    private func triggerImportIfNeeded() {
        if !hasImportedCards && !isImporting {
            isImporting = true
            
            Task { @MainActor in
                await CardImporter.importCards(context: modelContext) { newProgress in
                    self.importProgress = newProgress
                }
                
                await MainActor.run {
                    withAnimation {
                        hasImportedCards = true
                        isImporting = false
                    }
                }
            }
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

#Preview {
    // 1. Setup the in-memory schema
    let schema = Schema([Flashcard.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    
    do {
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        // 2. Seed some "Mock" data
        // Let's create 20 cards total
        for i in 1...20 {
            let card = Flashcard(
                id: i,
                hanzi: "汉字 \(i)",
                pinyin: "pīnyīn",
                english: "English",
                level: 1
            )
            
            // Make IDs 1-5 "Due" for review by setting a past date
            if i <= 5 {
                card.dueDate = Date.now.addingTimeInterval(-86400) // 24 hours ago
            }
            
            context.insert(card)
        }
        
        return ContentView()
            .modelContainer(container)
            // 3. Seed AppStorage so the badges calculate correctly
            .onAppear {
                UserDefaults.standard.set(5, forKey: "lastSeenID")
            }
            
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
