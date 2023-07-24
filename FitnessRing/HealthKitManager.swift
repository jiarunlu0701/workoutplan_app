import HealthKit

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        // Add more cases as needed
        default: return "Other"
        }
    }
}

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var activeCalories: CGFloat = 0
    @Published var basalCalories: CGFloat = 0
    @Published var workouts: [HKWorkout] = []
    @Published var heartRates: [HKWorkout: [HKQuantitySample]] = [:] // Corrected here
    @Published var heartRateGroups: [MinutelyHRSample] = []
    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    
    init() {
        authorizeHealthKitAccess()
    }
    
    func authorizeHealthKitAccess() {
        let typesToRead = Set([
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ])

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { (success, error) in
            if success {
                self.getactiveCaloriesBurned()
                self.getBasalEnergyBurned()
                self.getTodayWorkouts()
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func updateHeartRateGroupsFor(workout: HKWorkout) {
        if let heartRates = heartRates[workout] {
            let hrSamples = groupHeartRateSamplesByMinute(heartRates: heartRates)
            heartRateGroups = hrSamples.map {
                MinutelyHRSample(minute: $0.0, minHR: $0.1.min, maxHR: $0.1.max, avgHR: $0.1.avg)
            }
        }
    }

    func getHeartRateData(for workout: HKWorkout, completion: @escaping ([HKQuantitySample]) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample], error == nil else {
                print("Failed to fetch heart rate samples for workout \(workout) with error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            // Group heart rate samples by minute and store the result
            let hrSamples = self.groupHeartRateSamplesByMinute(heartRates: samples)
            DispatchQueue.main.async {
                self.heartRateGroups = hrSamples.map { MinutelyHRSample(minute: $0.0, minHR: $0.1.min, maxHR: $0.1.max, avgHR: $0.1.avg) }
            }
            completion(samples)
        }
        healthStore.execute(heartRateQuery)
    }


    func groupHeartRateSamplesByMinute(heartRates: [HKQuantitySample]) -> [(Date, (min: Int, max: Int, avg: Int))] {
        var groups: [(Date, (min: Int, max: Int, avg: Int))] = []
        var currentGroup: [Double] = []
        var currentMinute: Date? = nil

        for (index, sample) in heartRates.enumerated() {
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            currentGroup.append(heartRate)

            // Use the first sample's date as the minute indicator
            if currentMinute == nil {
                currentMinute = sample.startDate
            }

            if currentGroup.count == 4 { // Group every 4 samples (every minute)
                let minHeartRate = Int(currentGroup.min()!)
                let maxHeartRate = Int(currentGroup.max()!)
                let avgHeartRate = Int(currentGroup.reduce(0, +) / Double(currentGroup.count))
                groups.append((currentMinute!, (min: minHeartRate, max: maxHeartRate, avg: avgHeartRate)))
                currentGroup.removeAll() // Clear for the next group
                currentMinute = nil // Reset the minute
            }
        }

        // Handle last group if it has less than 4 samples
        if !currentGroup.isEmpty {
            let minHeartRate = Int(currentGroup.min()!)
            let maxHeartRate = Int(currentGroup.max()!)
            let avgHeartRate = Int(currentGroup.reduce(0, +) / Double(currentGroup.count))
            groups.append((currentMinute!, (min: minHeartRate, max: maxHeartRate, avg: avgHeartRate)))
        }

        return groups
    }

    func getTodayWorkouts() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) // Get start of yesterday
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                print("Failed to fetch workouts.")
                return
            }
            
            DispatchQueue.main.async {
                self.workouts = workouts
                
                // Fetch heart rate data for each workout
                workouts.forEach { workout in
                    self.getHeartRateData(for: workout) { heartRateSamples in
                        self.heartRates[workout] = heartRateSamples
                    }
                }
            }
        }
        healthStore.execute(query)
    }
    
    func getBasalEnergyBurned() {
        let quantityType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                self.basalCalories = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
        }
        
        healthStore.execute(query)
    }

    func getactiveCaloriesBurned() {
        let quantityType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }

            DispatchQueue.main.async {
                self.activeCalories = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
        }

        healthStore.execute(query)
    }
}
