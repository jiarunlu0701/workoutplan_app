import SwiftUI
import DGCharts
import HealthKit
import Foundation

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

struct HeartRateChartView: UIViewRepresentable {
    var heartRateSamples: [HKQuantitySample]
    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    // Create a stride of 5 minutes
    let stride = ChartStrideBy.minute.time
    func makeUIView(context: Context) -> BarChartView {
        let chartView = BarChartView()
        chartView.rightAxis.enabled = false
        chartView.leftAxis.axisMinimum = 0
        chartView.leftAxis.axisMaximum = 200
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.valueFormatter = DateValueFormatter(samples: heartRateSamples, stride: stride)
        
        let entries = heartRateSamples.enumerated().map { index, sample in
            BarChartDataEntry(x: Double(index), y: sample.quantity.doubleValue(for: heartRateUnit))
        }
        
        let dataSet = BarChartDataSet(entries: entries)
        dataSet.colors = [NSUIColor.red]
        let data = BarChartData(dataSet: dataSet)
        
        chartView.data = data
        
        return chartView
    }
    
    func updateUIView(_ uiView: BarChartView, context: Context) {}
}
    
    class DateValueFormatter: AxisValueFormatter {
        let dateFormatter = DateFormatter()
        let samples: [HKQuantitySample]
        let stride: Calendar.Component
        
        init(samples: [HKQuantitySample], stride: Calendar.Component) {
            self.samples = samples
            self.stride = stride
            dateFormatter.dateFormat = "HH:mm"
        }
        
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let date = samples[Int(value)].startDate
            
            // Apply the stride
            let stridedDate = Calendar.current.date(byAdding: stride, value: Int(value), to: date) ?? date
            
            return dateFormatter.string(from: stridedDate)
        }
    }

struct HeartRatePoint: Identifiable {
    let id = UUID()
    let time: Date
    let rate: Double
}

struct HRSample: Identifiable {
    let id = UUID()
    let date: Date
    let min: Int
    let max: Int
}

struct CalendarView: View {
    @EnvironmentObject var dietManager: DietManager
    @EnvironmentObject var ringViewModel: RingViewModel
    @StateObject private var appState = AppState()
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())

    var body: some View {
        ZStack {
            BackgroundView()
            ScrollView {
                VStack{
                    DateScrollBar(selectedDate: $selectedDate, workoutManager: appState.workoutManager)
                    FitnessRingView()
                        .environmentObject(ringViewModel)
                    // Display the calories
                    Text("Active Calories: \(Int(healthKitManager.activeCalories))")
                        .font(.title)
                        .padding()
                    Text("Resting Calories: \(Int(healthKitManager.basalCalories))")
                        .font(.title)
                        .padding()
                    Text("Total Calories: \(Int(healthKitManager.basalCalories))+\(Int(healthKitManager.activeCalories))")
                        .font(.title)
                        .padding()
                    
                    // Display workouts
                    VStack(alignment: .leading) {
                        Text("Today's Workouts")
                            .font(.title)
                            .padding(.bottom, 10)
                        ForEach(healthKitManager.workouts, id: \.uuid) { workout in
                            VStack(alignment: .leading) {
                                Text(workout.workoutActivityType.name)
                                    .font(.headline)
                                Text("Duration: \(workout.duration / 60, specifier: "%.2f") minutes") // Convert duration to minutes
                                Text("Calories Burned: \(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0, specifier: "%.2f")")
                                Text("Distance: \(workout.totalDistance?.doubleValue(for: .mile()) ?? 0, specifier: "%.2f") miles")
                                if let heartRates = healthKitManager.heartRates[workout] {
                                    Text("Average Heart Rate: \(averageHeartRate(samples: heartRates)) bpm")
                                    HeartRateChartView(heartRateSamples: heartRates)
                                        .frame(height: 300)
                                }
                            }
                            .padding(.bottom, 10)
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .onAppear {
                if let userId = UserAuth.getCurrentUserId() {
                    appState.workoutManager.fetchWorkoutPhasesForUser(userId: userId)
                }
                healthKitManager.getactiveCaloriesBurned()
                healthKitManager.getBasalEnergyBurned()
                healthKitManager.getTodayWorkouts()
            }
        }
    }
    
    func averageHeartRate(samples: [HKQuantitySample]) -> Double {
        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let totalHeartRate = samples.reduce(0) { (total, sample) -> Double in
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            return total + heartRate
        }
        return totalHeartRate / Double(samples.count)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FitnessRingView: View {
    @EnvironmentObject var ringViewModel: RingViewModel
    var body: some View {
        if !ringViewModel.isDataLoaded {
            ProgressView("Loading...")
        } else {
            VStack(spacing: 15){
                HStack(spacing: 20){
                    ZStack{
                        ForEach(ringViewModel.rings.indices, id: \.self){ index in
                            AnimatedRingView(ring: ringViewModel.rings[index], index: index)
                        }
                    }
                    .frame(width: 130, height: 130)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(ringViewModel.rings.indices, id: \.self){ index in
                            Label {
                                Spacer()
                                HStack(alignment: .bottom, spacing: 6) {
                                    Text("\(Int(ringViewModel.rings[index].userInput)) / \(Int(ringViewModel.rings[index].minValue))")
                                        .font(.title3.bold())
                                }
                            } icon: {
                                Group {
                                    switch ringViewModel.rings[index].keyIcon {
                                    case .system(let name):
                                        Image(systemName: name)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(ringViewModel.rings[index].iconColor)
                                    case .local(let name):
                                        Image(name)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(ringViewModel.rings[index].iconColor)
                                    }
                                }
                                .frame(width: 30)
                                let ring = ringViewModel.rings[index]
                                Text(ring.value)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.leading,10)
                }
                .padding(.top,20)
            }
            .padding(.horizontal,20)
            .padding(.vertical,25)
            .background(Color.clear)
            .onAppear {
                ringViewModel.loadData()
            }
            .onChange(of: ringViewModel.needsRefresh) { needsRefresh in
                if needsRefresh {
                    ringViewModel.loadData()
                    ringViewModel.needsRefresh = false
                }
            }
        }
    }
}

