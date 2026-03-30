import SwiftUI
import SwiftData

struct CardImporter {
    @MainActor
    static func importCards(context: ModelContext, level: Int? = nil, progress: @escaping (Double) -> Void) async {
        // 1. Check existing levels to avoid duplicates
        let existingLevelsDescriptor = FetchDescriptor<Flashcard>()
        let existingCards = (try? context.fetch(existingLevelsDescriptor)) ?? []
        let existingLevelSet = Set(existingCards.map { Int($0.level) })
        
        let levelsToImport: [Int]
        if let specificLevel = level {
            if existingLevelSet.contains(specificLevel) {
                print("Level \(specificLevel) already imported.")
                await MainActor.run { progress(1.0) }
                return
            }
            levelsToImport = [specificLevel]
        } else {
            levelsToImport = Array(1...6).filter { !existingLevelSet.contains($0) }
        }
        
        if levelsToImport.isEmpty {
            await MainActor.run { progress(1.0) }
            return
        }

        // 2. Determine the starting ID offset
        let descriptor = FetchDescriptor<Flashcard>(sortBy: [SortDescriptor(\.id, order: .reverse)])
        let lastCard = (try? context.fetch(descriptor))?.first
        var currentIDOffset = lastCard?.id ?? 0
        
        do {
            for (index, level) in levelsToImport.enumerated() {
                let currentProgress = Double(index) / Double(levelsToImport.count)
                await MainActor.run { progress(currentProgress) }
                
                try autoreleasepool {
                    let cardCount = try importCSV(startID: currentIDOffset + 1, level: level, context: context)
                    currentIDOffset += cardCount
                }
            }
            
            try context.save()
            await MainActor.run { progress(1.0) }
            print("Successfully imported \(levelsToImport.count) levels.")
            
        } catch {
            print("Import failed: \(error.localizedDescription)")
        }
    }
    
    private static func importCSV(startID: Int, level: Int, context: ModelContext) throws -> Int {
        guard let url = Bundle.main.url(forResource: "hsk\(level)", withExtension: "csv") else {
            print("Missing file: hsk\(level).csv")
            return 0
        }
        
        let content = try String(contentsOf: url)
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
                    hanzi: fields[1].trimmingCharacters(in: .whitespaces),
                    pinyin: fields[2].trimmingCharacters(in: .whitespaces),
                    english: fields[3].trimmingCharacters(in: .whitespaces),
                    level: Int16(level)
                )
                context.insert(card)
            }
        }
        
        return cardCount
    }
}
