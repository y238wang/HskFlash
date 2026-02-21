import SwiftUI
import SwiftData

struct StudyView: View {
    let initialCount: Int
    
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    
    @State private var cards: [Flashcard]
    @State private var finishedCount: Int = 0
    @State private var showDetail = false
    
    init(cards: [Flashcard]) {
        self.cards = cards
        initialCount = cards.count
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: Double(finishedCount) / Double(initialCount))
                    .tint(.blue)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                HStack {
                    Text("Cards Studied")
                    Spacer()
                    Text("\(finishedCount) / \(initialCount)")
                }
                .font(.caption2.bold().monospacedDigit())
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            if let card = cards.first {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(alignment: .topTrailing) {
                            Text("HSK \(card.level)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.gray.opacity(0.15)))
                                .foregroundColor(.gray)
                                .padding(12) // Distance from the corner
                        }
                    
                    VStack(spacing: 12) {
                        if showDetail {
                            Text(card.hanzi)
                                .font(.largeTitle)
                            Text(card.pinyin)
                                .foregroundColor(.secondary)
                            Text(card.english)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text(card.hanzi)
                                .font(.system(size: 56))
                        }
                    }
                }
                .onTapGesture { showDetail.toggle() }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Group {
                        RatingButton(title: "Again", color: .red) { finishCard(quality: 0) }
                        RatingButton(title: "Hard", color: .orange) { finishCard(quality: 1) }
                        RatingButton(title: "Good", color: .green) { finishCard(quality: 2) }
                    }
                    .opacity(showDetail ? 1 : 0)
                    .disabled(!showDetail)
                    
                    RatingButton(title: "Easy", color: .blue) { finishCard(quality: 3) }
                }
                .frame(height: 50)
            } else {
                ContentUnavailableView("Session Complete",
                   systemImage: "checkmark.circle.fill",
                   description: Text("You've reviewed all cards for this session."))
            }
        }
        .padding()
    }

    private func finishCard(quality: Int) {
        showDetail = false
        let card = cards.removeFirst()
        
        if quality == 0 {
            cards.append(card)
        } else {
            finishedCount += 1
        }
        
        Task { @MainActor in
            card.updateSRS(quality: quality)
            if card.id > lastSeenID {
                lastSeenID = card.id
            }
        }
    }
}

struct RatingButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(color, lineWidth: 1))
        }
    }
}

#Preview {
    let schema = Schema([Flashcard.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    
    do {
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        let mockCards = [
            Flashcard(id: 1, hanzi: "你好", pinyin: "nǐ hǎo", english: "Hello", level: 1),
            Flashcard(id: 2, hanzi: "谢谢", pinyin: "xièxie", english: "Thank you", level: 1),
            Flashcard(id: 3, hanzi: "再见", pinyin: "zàijiàn", english: "Goodbye", level: 1)
        ]
        
        for card in mockCards {
            context.insert(card)
        }
        
        return StudyView(cards: mockCards)
            .modelContainer(container)
            
    } catch {
        return Text("Preview error: \(error.localizedDescription)")
    }
}
