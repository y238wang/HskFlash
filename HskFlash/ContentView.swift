//
//  ContentView.swift
//  HskFlash
//
//  Created by Ivan Wang on 2026-02-07.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Flashcard.level) private var cards: [Flashcard]
    @State private var currentIndex = 0
    @State private var showDetail = false

    var body: some View {
        VStack {
            if cards.isEmpty {
                Text("No flashcards available.")
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
    let container = try! ModelContainer(for: Flashcard.self)
    
    let context = container.mainContext
    CardImporter.importCards(context: context)
    
    return ContentView()
        .modelContainer(container)
}
