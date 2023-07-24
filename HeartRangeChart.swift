import SwiftUI
import Charts

enum ChartStrideBy: Identifiable, CaseIterable {
    case second
    case minute
    case hour
    case day
    case weekday
    case weekOfYear
    case month
    case year
    
    var id: String { title }
    
    var title: String {
        switch self {
        case .second:
            return "Second"
        case .minute:
            return "Minute"
        case .hour:
            return "Hour"
        case .day:
            return "Day"
        case .weekday:
            return "Weekday"
        case .weekOfYear:
            return "Week of Year"
        case .month:
            return "Month"
        case .year:
            return "Year"
        }
    }
    
    var time: Calendar.Component {
        switch self {
        case .second:
            return .second
        case .minute:
            return .minute
        case .hour:
            return .hour
        case .day:
            return .day
        case .weekday:
            return .weekday
        case .weekOfYear:
            return .weekOfYear
        case .month:
            return .month
        case .year:
            return .year
        }
    }
}

struct HeartRateRangeChart: View {
    var isOverview: Bool

    @ObservedObject var data: HealthKitManager  // Use HealthKitManager as observed object

    @State private var barWidth = 10.0
    @State private var chartColor: Color = .red

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        if isOverview {
            chart
        } else {
            List {
                Section(header: header) {
                    chart
                }

                customisation
            }
        }
    }

    private var customisation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Bar Width: \(barWidth, specifier: "%.1f")")
                Slider(value: $barWidth, in: 5...20) {
                    Text("Bar Width")
                } minimumValueLabel: {
                    Text("5")
                } maximumValueLabel: {
                    Text("20")
                }
            }
            ColorPicker("Color Picker", selection: $chartColor)
        }
    }

    private var chart: some View {
        let minValue = Double(data.heartRateGroups.map(\.minHR).min() ?? 0)
        let maxValue = Double(data.heartRateGroups.map(\.maxHR).max() ?? 0)
        return Chart(data.heartRateGroups, id: \.minute) { dataPoint in
            Plot {
                BarMark(
                    x: .value("Minute", dataPoint.minute, unit: .minute),
                    yStart: .value("HR Min", dataPoint.minHR),
                    yEnd: .value("HR Max", dataPoint.maxHR),
                    width: .fixed(isOverview ? 8 : barWidth)
                )
                .clipShape(Capsule())
                .foregroundStyle(chartColor.gradient)
            }
            .accessibilityLabel(formatDate(dataPoint.minute))
            .accessibilityValue("\(Int(dataPoint.minHR)) to \(Int(dataPoint.maxHR)) BPM")
            .accessibilityHidden(isOverview)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: ChartStrideBy.minute.time)) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: .dateTime.minute(.twoDigits))
            }
        }
        .accessibilityChartDescriptor(self)
        .chartYAxis(isOverview ? .hidden : .automatic)
        .chartYScale(domain: [Double(minValue), Double(maxValue)])
        .chartXAxis(isOverview ? .hidden : .automatic)
        .frame(height: isOverview ? 500 : 200)
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Text("Range")
            Text("\(data.heartRateGroups.map(\.minHR).min() ?? 0)-\(data.heartRateGroups.map(\.maxHR).max() ?? 0) ")
                .font(.system(.title, design: .rounded))
                .foregroundColor(.primary)
            + Text("BPM")
            Text("Workout from \(formatDate(data.heartRateGroups.first?.minute ?? Date()))")
        }
        .fontWeight(.semibold)
    }
}

// MARK: - Accessibility

extension HeartRateRangeChart: AXChartDescriptorRepresentable {
    func makeChartDescriptor() -> AXChartDescriptor {
        let min = data.heartRateGroups.map(\.minHR).min() ?? 0
        let max = data.heartRateGroups.map(\.maxHR).max() ?? 0

        let xAxis = AXCategoricalDataAxisDescriptor(
            title: "Minute",
            categoryOrder: data.heartRateGroups.map { formatDate($0.minute) }
        )

        let yAxis = AXNumericDataAxisDescriptor(
            title: "Heart Rate",
            range: Double(min)...Double(max),
            gridlinePositions: []
        ) { value in "HR: \(Int(value)) BPM" }

        let series = AXDataSeriesDescriptor(
            name: "Last Workout",
            isContinuous: false,
            dataPoints: data.heartRateGroups.map {
                .init(x: formatDate($0.minute),
                      y: Double($0.avgHR),
                      label: "Min: \($0.minHR) BPM, Max: \($0.maxHR) BPM")
            }
        )

        return AXChartDescriptor(
            title: "Heart Rate range",
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}

// MARK: - Preview

struct HeartRateRangeChart_Previews: PreviewProvider {
    static var previews: some View {
        HeartRateRangeChart(isOverview: true, data: HealthKitManager())
        HeartRateRangeChart(isOverview: false, data: HealthKitManager())
    }
}
