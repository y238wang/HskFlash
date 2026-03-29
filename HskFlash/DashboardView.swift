import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    
    @Query private var observer: [Flashcard]

    @State private var viewModel = DashboardViewModel()
    
    var body: some View {
        HStack(spacing: 15) {
            StatusBadge(label: "Due", text: String(viewModel.dueCount), color: .orange)
            StatusBadge(label: "New", text: String(min(viewModel.newCount, 20)), color: .blue)
            StatusBadge(label: "Seen", text: "\(lastSeenID)/\(viewModel.totalCount)", color: .gray)
        }
        .onAppear {
            viewModel.update(context: modelContext, lastSeenID: lastSeenID)
        }
        .onChange(of: observer) { _, _ in
            viewModel.update(context: modelContext, lastSeenID: lastSeenID)
        }
        .onChange(of: lastSeenID) { _, _ in
            viewModel.update(context: modelContext, lastSeenID: lastSeenID)
        }
    }
}

struct StatusBadge: View {
    let label: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(text)
                .font(.headline)
            Text(label)
                .font(.system(.caption2, design: .default).uppercaseSmallCaps())
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    let container = try! ModelContainer(for: Flashcard.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    return DashboardView()
        .modelContainer(container)
        .padding()
}
