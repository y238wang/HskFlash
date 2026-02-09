import SwiftData

@Model
class Flashcard {
    var hanzi: String
    var pinyin: String
    var english: String
    var level: Int16
    
    init(hanzi: String, pinyin: String, english: String, level: Int16) {
        self.hanzi = hanzi
        self.pinyin = pinyin
        self.english = english
        self.level = level
    }
}
