import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Connect to the same flag used in HskFlashApp
    @AppStorage("hasImportedCards") private var hasImportedCards: Bool = false
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    
    @State private var isShowingResetAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Data Management")) {
                    Button(role: .destructive) {
                        isShowingResetAlert = true
                    } label: {
                        Label("Reset & Reimport Cards", systemImage: "arrow.clockwise.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Reset All Progress?", isPresented: $isShowingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset Everything", role: .destructive) {
                    resetData()
                }
            } message: {
                Text("This will delete all your SRS progress and re-run the initial HSK card import. This cannot be undone.")
            }
        }
    }

    private func resetData() {
        // 1. Delete all existing Flashcard objects from the database
        try? modelContext.delete(model: Flashcard.self)
        
        // 2. Reset the pointers
        lastSeenID = 0
        
        // 3. Set this to false so HskFlashApp's logic triggers the import
        hasImportedCards = false
        
        // 4. Close the settings view
        dismiss()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Flashcard.self, inMemory: true)
}
