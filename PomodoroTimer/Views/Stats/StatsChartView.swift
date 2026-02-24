import SwiftUI
import Charts

struct StatsChartView: View {
    @Environment(StatsViewModel.self) private var statsVM

    var body: some View {
        @Bindable var vm = statsVM

        VStack(alignment: .leading, spacing: 12) {
            // Period picker
            Picker("Period", selection: $vm.selectedPeriod) {
                ForEach(StatsPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)

            let points = statsVM.dataPoints(for: statsVM.selectedPeriod)

            if points.allSatisfy({ $0.focusMinutes == 0 }) {
                // Empty state
                ContentUnavailableView(
                    "No data yet",
                    systemImage: "chart.bar",
                    description: Text("Complete focus sessions to see your stats here.")
                )
                .frame(height: 160)
            } else {
                Chart(points) { point in
                    BarMark(
                        x: .value("Period", point.label),
                        y: .value("Minutes", point.focusMinutes)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                    .annotation(position: .top, alignment: .center) {
                        if point.focusMinutes > 0 {
                            Text("\(Int(point.focusMinutes))m")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks { _ in AxisValueLabel() }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))m")
                            }
                        }
                    }
                }
            }

            // Summary row
            if !points.isEmpty {
                let total = points.reduce(0) { $0 + $1.focusMinutes }
                HStack {
                    Text("Total: \(Int(total)) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(points.reduce(0) { $0 + $1.sessionCount }) sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
