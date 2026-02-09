import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack { // This enables the "Push/Pop" navigation
            VStack(spacing: 20) {
                Text("HSK Flash")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 40)

                // NavigationLink moves the user to the StudyView
                NavigationLink {
                    StudyView()
                } label: {
                    MenuButton(title: "Learn", icon: "book.fill", color: .blue)
                }

                // Placeholder for Settings
                Button {
                    print("Settings tapped")
                } label: {
                    MenuButton(title: "Settings", icon: "gearshape.fill", color: .gray)
                }

                Spacer()
            }
            .padding()
        }
    }
}

// A reusable UI component for your buttons
struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color, lineWidth: 2)
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Flashcard.self, configurations: config)
    
    return ContentView()
        .modelContainer(container)
}
