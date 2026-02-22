import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("hasImportedCards") private var hasImportedCards: Bool = false
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    @AppStorage("hskLevel") private var hskLevel: Int = 1
    
    @State private var cardsForSession: [Flashcard]? = nil
    @State private var isShowingSettings = false
    @State private var isImporting = false
    @State private var importProgress: Double = 0.0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    Text("HSK Flash")
                        .font(.system(size: 40))
                    
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(.bottom, 40)
                
                DashboardView()
                .padding(.bottom, 20)

                Button {
                    prepareSession()
                } label: {
                    MenuButton(title: "Study", icon: "book.fill", color: .blue)
                }
                
                NavigationLink(destination: CardListView()) {
                    MenuButton(title: "Card List", icon: "character.book.closed.fill", color: .green)
                }

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
                await CardImporter.importCards(context: modelContext, level: hskLevel) { newProgress in
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
        cardsForSession = StudyService.prepareSession(context: modelContext, lastSeenID: lastSeenID)
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Text(title)
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary.opacity(0.8))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    let schema = Schema([Flashcard.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    
    do {
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        for i in 1...20 {
            let card = Flashcard(
                id: i,
                hanzi: "汉字 \(i)",
                pinyin: "pīnyīn",
                english: "English",
                level: 1
            )
            
            if i <= 5 {
                card.dueDate = Date.now.addingTimeInterval(-86400) // 24 hours ago
            }
            
            context.insert(card)
        }
        
        return ContentView()
            .modelContainer(container)
            .onAppear {
                UserDefaults.standard.set(5, forKey: "lastSeenID")
            }
            
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
