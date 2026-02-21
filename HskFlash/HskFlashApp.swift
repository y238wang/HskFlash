import SwiftUI
import SwiftData

@main
struct HskFlashApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Flashcard.self)
        }
    }
}
