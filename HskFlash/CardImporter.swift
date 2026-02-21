import SwiftUI
import SwiftData

struct CardImporter {
    static func importCards(context: ModelContext) {
        var currentIDOffset = 0
        
        for level in 1...6 {
            let cardCount = importCSV(startID: currentIDOffset + 1, level: level, context: context)
            currentIDOffset += cardCount
        }
    }
    
    private static func importCSV(startID: Int, level: Int, context: ModelContext) -> Int {
        guard let url = Bundle.main.url(forResource: "hsk\(level)", withExtension: "csv"),
              let content = try? String(contentsOf: url) else { return 0 }
        
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let cardCount = lines.count
        
        let idRange = startID..<(startID + cardCount)
        var shuffledIDs = Array(idRange).shuffled()
        
        for line in lines {
            let fields = line.components(separatedBy: ",")
            if fields.count >= 4 {
                guard !shuffledIDs.isEmpty else { break }
                let nextID = shuffledIDs.removeFirst()
                
                let card = Flashcard(
                    id: nextID,
                    hanzi: fields[1],
                    pinyin: fields[2],
                    english: fields[3],
                    level: Int16(level)
                )
                context.insert(card)
            }
        }
        
        return cardCount
    }
}
