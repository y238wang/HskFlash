//
//  CardImporter.swift
//  HskFlash
//
//  Created by Ivan Wang on 2026-02-07.
//

import SwiftUI
import SwiftData

struct CardImporter {
    static func importCards(context: ModelContext) {
        for level in 1...6 {
            importCSV(level: level, context: context)
        }
    }
    
    private static func importCSV(level: Int, context: ModelContext) {
        guard let url = Bundle.main.url(forResource: "hsk\(level)", withExtension: "csv") else {
            print("CSV file for level \(level) not found.")
            return
        }
        
        do {
            let content = try String(contentsOf: url)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                guard !line.isEmpty else { continue }
                let fields = line.components(separatedBy: ",")
                if fields.count >= 4 {
                    let card = Flashcard(hanzi: fields[1], pinyin: fields[2], english: fields[3], level: Int16(level))
                    context.insert(card)
                }
            }
        } catch {
            print("Error reading CSV file for level \(level): \(error)")
        }
    }
}
