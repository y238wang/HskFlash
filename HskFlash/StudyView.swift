import SwiftUI
import SwiftData

struct StudyView: View {
    @Query(sort: \Flashcard.level) private var cards: [Flashcard]
    @State private var currentIndex = 0
    @State private var showDetail = false

    var body: some View {
        VStack {
            if cards.isEmpty {
                ContentUnavailableView("No Cards Found",
                    systemImage: "book.closed",
                    description: Text("Check your CSV import logic."))
            } else {
                let card = cards[currentIndex]
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                    
                    VStack(spacing: 12) {
                        if showDetail {
                            Text(card.hanzi)
                                .font(.largeTitle)
                            Text(card.pinyin)
                                .foregroundColor(.secondary)
                            Text(card.english)
                        } else {
                            Text(card.hanzi)
                                .font(.system(size: 48))
                        }
                    }
                }
                .onTapGesture { showDetail.toggle() }
                Spacer()
                HStack(spacing: 40) {
                    Button("Prev") { move(-1) }
                    Button("Next") { move(1) }
                }
            }
        }
        .padding()
    }
    
    private func move(_ delta: Int) {
        showDetail = false
        currentIndex = (currentIndex + delta + cards.count) % cards.count
    }
}

#Preview {
    let schema = Schema([Flashcard.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    
    CardImporter.importCards(context: container.mainContext)
    
    return NavigationStack {
        StudyView()
    }
    .modelContainer(container)
}
