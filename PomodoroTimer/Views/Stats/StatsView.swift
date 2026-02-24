import SwiftUI

/// Root stats screen with chart on top, history list below.
struct StatsView: View {
    @Environment(StatsViewModel.self) private var statsVM
    @State private var showClearConfirm = false
    @State private var exportMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StatsChartView()
                    .padding()

                Divider()

                SessionHistoryView()
            }
            .navigationTitle("Statistics")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Export CSV") { handleExport() }
                    Button("Clear", role: .destructive) { showClearConfirm = true }
                }
            }
            .alert("Clear History?", isPresented: $showClearConfirm) {
                Button("Clear", role: .destructive) { statsVM.clearHistory() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All session records will be permanently deleted.")
            }
            .overlay(alignment: .bottom) {
                if let msg = exportMessage {
                    Text(msg)
                        .font(.caption)
                        .padding(8)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            Task {
                                try? await Task.sleep(nanoseconds: 3_000_000_000)
                                exportMessage = nil
                            }
                        }
                }
            }
        }
        .frame(minWidth: 460, minHeight: 480)
    }

    private func handleExport() {
        if let url = statsVM.exportCSV() {
            exportMessage = "Saved to \(url.lastPathComponent)"
        } else {
            exportMessage = "Export failed"
        }
    }
}
