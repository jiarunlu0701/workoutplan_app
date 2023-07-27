import SwiftUI
import DGCharts
import HealthKit
import Foundation
import Charts

struct MinutelyHRSample {
    let minute: Date
    let minHR: Int
    let maxHR: Int
    let avgHR: Int
}


struct CalendarView: View {
    @State private var barWidth = 10.0
    @State private var chartColor: Color = .red
    @EnvironmentObject var dietManager: DietManager
    @EnvironmentObject var ringViewModel: RingViewModel
    @StateObject private var appState = AppState()
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    var heartRateSamples: [HKQuantitySample]  // Add this property

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
                    Text("Total Calories: \(Int(healthKitManager.basalCalories)+Int(healthKitManager.activeCalories))")
                        .font(.title)
                        .padding()
                    Text("Sleep Hours: \(healthKitManager.sleepHours, specifier: "%.2f")")
                        .font(.title)
                        .padding()
                    Text("Time in Bed: \(healthKitManager.inBedHours, specifier: "%.2f") hours")
                        .font(.title)
                        .padding()
                    // Display workouts
                    VStack(alignment: .leading) {
                        Text("Today's Workouts")
                            .font(.title)
                            .padding(.bottom, 10)
                        ForEach(healthKitManager.workouts, id: \.uuid) { (workout: HKWorkout) in
                            VStack(alignment: .leading) {
                                Text(workout.workoutActivityType.name)
                                    .font(.headline)
                                Text("Duration: \(workout.duration / 60, specifier: "%.2f") minutes") // Convert duration to minutes
                                Text("Calories Burned: \(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0, specifier: "%.2f")")
                                Text("Distance: \(workout.totalDistance?.doubleValue(for: .mile()) ?? 0, specifier: "%.2f") miles")
                                if let heartRates = healthKitManager.heartRates[workout] {
                                    Text("Average Heart Rate: \(averageHeartRate(samples: heartRates)) bpm")
                                    if healthKitManager.isHeartRateDataLoading {
                                        ProgressView("Loading Heart Rate Data...")
                                    } else if let heartRateGroups = healthKitManager.heartRateGroups[workout], !heartRateGroups.isEmpty {
                                        HeartRateRangeChart(isOverview: false, data: heartRateGroups, selectedWorkout: workout)
                                            .onAppear {
                                                healthKitManager.selectedWorkout = workout  // set selected workout
                                            }
                                            .frame(height: 360)
                                            .background(Color.clear) // Set the chart's background to clear
                                    }
                                } else {
                                    EmptyView()
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
                healthKitManager.getSleepHours()  // Get sleep hours
                healthKitManager.getInBedHours()  // Get in-bed hours
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
