import SwiftUI
import Charts
import HealthKit  // <-- Make sure this import is at the top of your file

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
    var data: [MinutelyHRSample]
    var selectedWorkout: HKWorkout

    @State private var barWidth = 5.0
    @State private var chartColor: Color = .red
    @State private var isHeartRateDataLoading = true // Add this state variable

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        Group {
            if isOverview {
                chart
                    .background(Color.white) // Set chart background to white
                    .overlay(loadingOverlay) // Add loading overlay
            } else {
                List {
                    Section(header: header) {
                        chart
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .background(Color.white) // Set chart background to white
                            .overlay(loadingOverlay) // Add loading overlay
                    }
                }
                .listStyle(PlainListStyle()) // Use plain list style
                .background(Color.white) // Set list background to white
            }
        }
        .environment(\.colorScheme, .light) // enforce light mode
        .onAppear {
            // Simulate loading with a slight delay (you can replace this with your actual loading logic)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isHeartRateDataLoading = false
            }
        }
    }

    @ViewBuilder
    private var chart: some View {
        // Display a ProgressView while loading the chart data
        if isHeartRateDataLoading {
            ProgressView("Loading Heart Rate Data...")
                .frame(height: isOverview ? 500 : 200) // Set the frame to match the chart height
        } else {
            let minValue = Double(data.map(\.minHR).min() ?? 0)
            let maxValue = Double(data.map(\.maxHR).max() ?? 0)
            Chart(data, id: \.minute) { dataPoint in
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
                AxisMarks(values: .stride(by: 2)) { _ in
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
            .background(Color.white)  // Set the background color here
        }
    }
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                ProgressView("Loading Heart Rate Data...")
                    .foregroundColor(.white)
            )
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Text("Range")
            Text("\(data.map(\.minHR).min() ?? 0)-\(data.map(\.maxHR).max() ?? 0) ")
                .font(.system(.title, design: .rounded))
                .foregroundColor(.primary)
            + Text("BPM")
            Text("Workout from \(formatDate(data.first?.minute ?? Date()))")
        }
        .fontWeight(.semibold)
    }
}

// MARK: - Accessibility
extension HeartRateRangeChart: AXChartDescriptorRepresentable {
    func makeChartDescriptor() -> AXChartDescriptor {
        let min = data.map(\.minHR).min() ?? 0
        let max = data.map(\.maxHR).max() ?? 0

        let xAxis = AXCategoricalDataAxisDescriptor(
            title: "Minute",
            categoryOrder: data.map { formatDate($0.minute) }
        )

        let yAxis = AXNumericDataAxisDescriptor(
            title: "Heart Rate",
            range: Double(min)...Double(max),
            gridlinePositions: []
        ) { value in "HR: \(Int(value)) BPM" }

        let series = AXDataSeriesDescriptor(
            name: "Last Workout",
            isContinuous: false,
            dataPoints: data.map {
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
        // Mock the data
        let mockWorkout = HKWorkout(activityType: .running, start: Date(), end: Date())
        let mockData = [MinutelyHRSample(minute: Date(), minHR: 60, maxHR: 120, avgHR: 80)]

        HeartRateRangeChart(isOverview: true, data: mockData, selectedWorkout: mockWorkout)
        HeartRateRangeChart(isOverview: false, data: mockData, selectedWorkout: mockWorkout)
    }
}
