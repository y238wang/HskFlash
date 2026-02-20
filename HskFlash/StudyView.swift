import SwiftUI
import SwiftData

struct StudyView: View {
    let cards: [Flashcard]

    @Environment(\.dismiss) private var dismiss
    @State private var sessionCards: [Flashcard] = []
    @State private var totalInitialCount: Int = 0
    @State private var finishedCount: Int = 0
    @State private var showDetail = false
    
    private var progress: Double {
        guard totalInitialCount > 0 else { return 0 }
        return Double(finishedCount) / Double(totalInitialCount)
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: progress)
                    .tint(.blue)
                    .scaleEffect(x: 1, y: 2, anchor: .center) // Make it slightly thicker
                
                HStack {
                    Text("Session Progress")
                    Spacer()
                    Text("\(finishedCount) / \(totalInitialCount)")
                }
                .font(.caption2.bold().monospacedDigit())
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            if let card = sessionCards.first {
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
                
                HStack(spacing: 8) {
                    if showDetail {
                        RatingButton(title: "Again", color: .red) { handleAgain() }
                        RatingButton(title: "Hard", color: .orange) { finishCard(quality: 1) }
                        RatingButton(title: "Good", color: .green) { finishCard(quality: 2) }
                    }
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
        .onAppear {
            if sessionCards.isEmpty {
                sessionCards = cards.shuffled()
                totalInitialCount = sessionCards.count
            }
        }
    }
    
    private func handleAgain() {
        showDetail = false
        let card = sessionCards.removeFirst()
        card.updateSRS(quality: 0)
        sessionCards.append(card)
    }

    private func finishCard(quality: Int) {
        showDetail = false
        let card = sessionCards.removeFirst()
        card.updateSRS(quality: quality)
        finishedCount += 1
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
    let container = try! ModelContainer(for: schema, configurations: config)
    
    CardImporter.importCards(context: container.mainContext)
    
    let descriptor = FetchDescriptor<Flashcard>()
    let allCards = (try? container.mainContext.fetch(descriptor)) ?? []
    
    return NavigationStack {
        StudyView(cards: Array(allCards.prefix(10)))
    }
    .modelContainer(container)
}
