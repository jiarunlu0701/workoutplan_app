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
    @State private var shouldDisplayGraph = false
    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    var heartRateSamples: [HKQuantitySample]  // Add this property

    var body: some View {
        ZStack {
            BackgroundView()
            ScrollView {
                VStack{
                    DateScrollBar(selectedDate: $selectedDate, workoutManager: appState.workoutManager)
                        .onChange(of: selectedDate) { newDate in
                            healthKitManager.getInBedHours(for: newDate)
                            healthKitManager.getactiveCaloriesBurned(for: newDate)
                            healthKitManager.getBasalEnergyBurned(for: newDate)
                            healthKitManager.getTodayWorkouts(for: newDate)
                            healthKitManager.getSleepHours(for: newDate)
                            shouldDisplayGraph = false  // Reset shouldDisplayGraph to false
                        }
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
                                Text("Duration: \(workout.duration / 60, specifier: "%.2f") minutes")
                                Text("Calories Burned: \(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0, specifier: "%.2f")")
                                Text("Distance: \(workout.totalDistance?.doubleValue(for: .mile()) ?? 0, specifier: "%.2f") miles")
                                if let heartRates = healthKitManager.heartRates[workout] {
                                    Text("Average Heart Rate: \(averageHeartRate(samples: heartRates)) bpm")
                                    
                                    Button(action: {
                                        shouldDisplayGraph.toggle()
                                    }) {
                                        HStack {
                                            Image(systemName: shouldDisplayGraph ? "minus.circle" : "heart.text.square")
                                            Text(shouldDisplayGraph ? "Hide Heart Rate Chart" : "Show Heart Rate Chart")
                                        }
                                    }.padding()
                                    
                                    if healthKitManager.isHeartRateDataLoading {
                                        ProgressView("Loading Heart Rate Data...")
                                    } else if let heartRateGroups = healthKitManager.heartRateGroups[workout], shouldDisplayGraph {
                                        HeartRateRangeChart(isOverview: false, data: heartRateGroups, selectedWorkout: workout)
                                            .onAppear {
                                                healthKitManager.selectedWorkout = workout
                                            }
                                            .frame(height: 360)
                                            .background(Color.clear)
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
                DispatchQueue.global(qos: .background).async {
                    if let userId = UserAuth.getCurrentUserId() {
                        appState.workoutManager.fetchWorkoutPhasesForUser(userId: userId)
                    }
                    healthKitManager.getactiveCaloriesBurned(for: Date())
                    healthKitManager.getBasalEnergyBurned(for: Date())
                    healthKitManager.getTodayWorkouts(for: Date())
                    healthKitManager.getSleepHours(for: Date())
                    healthKitManager.getInBedHours(for: Date())  // Add this line
                }
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
