import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("lastSeenID") private var lastSeenID: Int = 0
    
    @State private var viewModel = DashboardViewModel()
    
    var body: some View {
        HStack(spacing: 15) {
            StatusBadge(label: "Due", count: viewModel.dueCount, color: .orange)
            StatusBadge(label: "New", count: min(viewModel.newCount, 10), color: .blue)
        }
        .onAppear {
            viewModel.update(context: modelContext, lastSeenID: lastSeenID)
        }
    }
}

struct StatusBadge: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
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
