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
    @Published var basalCalories: CGFloat = 0  // Add this line
    @Published var workouts: [HKWorkout] = []  // Store the workouts
    @Published var heartRates: [HKWorkout: [HKQuantitySample]] = [:] // Store the heart rate data

    
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

    func getHeartRateData(for workout: HKWorkout, completion: @escaping ([HKQuantitySample]) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample], error == nil else {
                print("Failed to fetch heart rate samples for workout \(workout) with error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            completion(samples)
        }
        healthStore.execute(heartRateQuery)
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
