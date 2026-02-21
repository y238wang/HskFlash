import SwiftUI
import SwiftData

@main
struct HskFlashApp: App {
    @AppStorage("hasImportedCards") private var hasImportedCards: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Flashcard.self) { result in
                    if case .success(let container) = result {
                        if !hasImportedCards {
                            CardImporter.importCards(context: container.mainContext)
                            hasImportedCards = true
                        }
                    }
                }
        }
    }
}
