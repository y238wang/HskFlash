import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("hasImportedCards") private var hasImportedCards: Bool = false
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    @AppStorage("hskLevel") private var hskLevel: Int = 1
    
    @Query private var allCards: [Flashcard]
    
    private var loadedLevels: Set<Int> {
        Set(allCards.map { Int($0.level) })
    }
    
    @State private var selectedLevelToAdd: Int = 1
    @State private var isShowingResetAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Currently Loaded Levels")) {
                    if loadedLevels.isEmpty {
                        Text("No levels loaded")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(loadedLevels.sorted(), id: \.self) { level in
                            Text("HSK \(level)")
                        }
                    }
                }
                
                Section(header: Text("Add New Level")) {
                    Picker("Select Level", selection: $selectedLevelToAdd) {
                        ForEach(1...6, id: \.self) { level in
                            Text("HSK \(level)").tag(level)
                        }
                    }
                    .pickerStyle(.menu)

                    Button {
                        addNewLevel()
                    } label: {
                        Label("Add HSK \(selectedLevelToAdd)", systemImage: "plus.circle")
                    }
                    .disabled(loadedLevels.contains(selectedLevelToAdd))
                    
                    if loadedLevels.contains(selectedLevelToAdd) {
                        Text("This level is already in your deck.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("Data Management"), footer: Text("Resetting will delete ALL cards and ALL SRS progress. This cannot be undone.")) {
                    Button(role: .destructive) {
                        isShowingResetAlert = true
                    } label: {
                        Label("Reset Everything", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Confirm Reset", isPresented: $isShowingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset Everything", role: .destructive) {
                    resetEverything()
                }
            } message: {
                Text("This will delete all progress and remove all cards from your collection.")
            }
        }
    }

    private func addNewLevel() {
        // Just trigger the re-import by setting hasImportedCards to false.
        // ContentView will see this and call CardImporter with hskLevel.
        hskLevel = selectedLevelToAdd
        hasImportedCards = false
        dismiss()
    }

    private func resetEverything() {
        // 1. Wipe everything
        try? modelContext.delete(model: Flashcard.self)
        
        // 2. Update the level preference to HSK 1
        hskLevel = 1
        
        // 3. Reset pointers
        lastSeenID = 0
        
        // 4. Reset the import flag to trigger a fresh import of HSK 1
        hasImportedCards = false
        
        dismiss()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Flashcard.self, inMemory: true)
}
