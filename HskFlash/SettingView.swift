import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("hasImportedCards") private var hasImportedCards: Bool = false
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    @AppStorage("hskLevel") private var hskLevel: Int = 1
    
    @State private var selectedLevelToReset: Int
    @State private var isShowingResetAlert = false
    
    init() {
        let currentLevel = UserDefaults.standard.integer(forKey: "hskLevel")
        self._selectedLevelToReset = State(initialValue: currentLevel == 0 ? 1 : currentLevel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Current Session")) {
                    LabeledContent("Study Level", value: "HSK \(hskLevel)")
                }
                
                Section(header: Text("Data Management"), footer: Text("Resetting will delete all SRS progress and reload the selected level.")) {
                    Picker("Level to Load", selection: $selectedLevelToReset) {
                        ForEach(1...6, id: \.self) { level in
                            Text("HSK \(level)").tag(level)
                        }
                    }
                    .pickerStyle(.menu)

                    Button(role: .destructive) {
                        isShowingResetAlert = true
                    } label: {
                        Label("Reset & Load HSK \(selectedLevelToReset)", systemImage: "arrow.clockwise.circle")
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
                    resetAndLoadNewLevel()
                }
            } message: {
                Text("This will delete all progress and switch your deck to HSK \(selectedLevelToReset).")
            }
        }
    }

    private func resetAndLoadNewLevel() {
        // 1. Wipe everything
        try? modelContext.delete(model: Flashcard.self)
        
        // 2. Update the level preference to the user's new choice
        hskLevel = selectedLevelToReset
        
        // 3. Reset pointers
        lastSeenID = 0
        
        // 4. Trigger the re-import
        hasImportedCards = false
        
        dismiss()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Flashcard.self, inMemory: true)
}
