import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    @State private var cards: [Flashcard]
    @State private var missedCardIDs: Set<Int> = []
    @State private var finishedCount: Int = 0
    @State private var showDetail = false
    let initialCount: Int
    
    init(cards: [Flashcard]) {
        self.cards = cards
        initialCount = cards.count
    }

    var body: some View {
        VStack {
            // Progress Header
            VStack(alignment: .center) {
                ProgressView(value: Double(finishedCount) / Double(initialCount))
                    .tint(.blue)
                Text("\(finishedCount) / \(initialCount)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)

            if let card = cards.first {
                Spacer()
                
                VStack {
                    Text("HSK \(card.level)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.primary.opacity(0.05)))
                        .foregroundColor(.secondary)
                        .padding(20)
                    
                    Text(card.hanzi)
                        .font(.system(size: 64, design: .serif))
                        .frame(height: 90)
                    
                    VStack {
                        if showDetail {
                            Text(card.pinyin)
                                .font(.system(.title3, design: .rounded))
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text(card.english)
                                .font(.headline)
                                .fontWeight(.regular)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                RectButton(icon: "xmark", label: "Incorrect", color: .red) { finishCard(quality: 0) }
                                RectButton(icon: "checkmark", label: "Correct", color: .green) { correctCard() }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        } else {
                            Spacer()
                            Label("Tap to reveal", systemImage: "hand.tap")
                                .font(.system(.caption, design: .rounded).bold())
                                .foregroundColor(.secondary.opacity(0.7))
                                .padding(.bottom, 20)
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)
                .onTapGesture { showDetail.toggle() }
                
                Spacer()
                
                HStack {
                    Spacer().frame(maxWidth: .infinity)
                    RectButton(icon: "chevron.right", label: "Easy", color: .blue) { finishCard(quality: 5) }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 25)
                
            } else {
                ContentUnavailableView {
                    Label("All Done!", systemImage: "sparkles")
                } actions: {
                    RectButton(
                        icon: "chevron.left",
                        label: "Go Back",
                        color: .purple,
                        action: {
                            dismiss()
                        }
                    )
                    .padding(.top, 30)
                }
            }
        }
    }
    
    private func correctCard() {
        guard let currentID = cards.first?.id else { return }
        let quality = missedCardIDs.contains(currentID) ? 1 : 3
        finishCard(quality: quality)
    }

    private func finishCard(quality: Int) {
        showDetail = false
        let card = cards.removeFirst()
        if quality == 0 {
            cards.append(card)
            missedCardIDs.insert(card.id)
        } else {
            finishedCount += 1
        }
        
        Task { @MainActor in
            card.updateSRS(quality: quality)
            if card.id > lastSeenID { lastSeenID = card.id }
        }
    }
}

struct RectButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .padding(.horizontal, 30)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
            )
        }
        .buttonStyle(.plain) // Removes the default "flash" on tap for a cleaner feel
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
