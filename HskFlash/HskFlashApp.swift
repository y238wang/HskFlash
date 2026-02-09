import SwiftUI
import SwiftData

@main
struct HskFlashApp: App {
    @AppStorage("hasImportedCards") private var hasImportedCards: Bool = false
    
    var container: ModelContainer = {
        let schema = Schema([Flashcard.self])
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not configure SwiftData container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .onAppear {
                    if !hasImportedCards {
                        CardImporter.importCards(context: container.mainContext)
                        hasImportedCards = true
                    }
                }
        }
    }
}
