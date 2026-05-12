import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("hasImportedCards") private var hasImportedCards: Bool = false
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    @AppStorage("levelsToImportBitmask") private var levelsToImportBitmask: Int = 1
    @AppStorage("enabledLevelsBitmask") private var enabledLevelsBitmask: Int = 1
    
    @Query private var allCards: [Flashcard]
    
    private var loadedLevels: Set<Int> {
        Set(allCards.map { Int($0.level) })
    }
    
    @State private var isShowingResetAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("HSK Levels")) {
                    HStack {
                        Button("Select All") {
                            selectAllLoaded()
                        }
                        .buttonStyle(.borderless)
                        
                        Spacer()
                        
                        Button("Deselect All") {
                            enabledLevelsBitmask = 0
                        }
                        .buttonStyle(.borderless)
                    }
                    .font(.caption)
                    
                    ForEach(1...6, id: \.self) { level in
                        let isLoaded = loadedLevels.contains(level)
                        HStack {
                            Text("HSK \(level)")
                            
                            Spacer()
                            
                            if isLoaded {
                                Toggle("", isOn: Binding(
                                    get: { (enabledLevelsBitmask & (1 << (level - 1))) != 0 },
                                    set: { newValue in
                                        if newValue {
                                            enabledLevelsBitmask |= (1 << (level - 1))
                                        } else {
                                            enabledLevelsBitmask &= ~(1 << (level - 1))
                                        }
                                    }
                                ))
                                .labelsHidden()
                            } else {
                                Button {
                                    importLevel(level)
                                } label: {
                                    Text("Import")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    if loadedLevels.count < 6 {
                        Button {
                            importAllMissing()
                        } label: {
                            Label("Import All Missing Levels", systemImage: "arrow.down.circle")
                        }
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

    private func selectAllLoaded() {
        var mask = 0
        for level in loadedLevels {
            mask |= (1 << (level - 1))
        }
        enabledLevelsBitmask = mask
    }

    private func importLevel(_ level: Int) {
        levelsToImportBitmask = (1 << (level - 1))
        hasImportedCards = false
        dismiss()
    }

    private func importAllMissing() {
        var mask = 0
        for level in 1...6 {
            if !loadedLevels.contains(level) {
                mask |= (1 << (level - 1))
            }
        }
        levelsToImportBitmask = mask
        hasImportedCards = false
        dismiss()
    }

    private func resetEverything() {
        // 1. Wipe everything
        try? modelContext.delete(model: Flashcard.self)
        
        // 2. Reset preferences
        levelsToImportBitmask = 1
        enabledLevelsBitmask = 1
        
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
