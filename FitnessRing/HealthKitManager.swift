import HealthKit

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        // Individual sports
        case .archery: return "Archery"
        case .bowling: return "Bowling"
        case .fencing: return "Fencing"
        case .gymnastics: return "Gymnastics"
        case .trackAndField: return "Track and Field"
        
        // Team sports
        case .americanFootball: return "American Football"
        case .australianFootball: return "Australian Football"
        case .baseball: return "Baseball"
        case .basketball: return "Basketball"
        case .cricket: return "Cricket"
        case .discSports: return "Disc Sports"
        case .handball: return "Handball"
        case .hockey: return "Hockey"
        case .lacrosse: return "Lacrosse"
        case .rugby: return "Rugby"
        case .soccer: return "Soccer"
        case .softball: return "Softball"
        case .volleyball: return "Volleyball"
        
        // Exercise and fitness
        case .preparationAndRecovery: return "Preparation and Recovery"
        case .flexibility: return "Flexibility"
        case .cooldown: return "Cooldown"
        case .walking: return "Walking"
        case .running: return "Running"
        case .wheelchairWalkPace: return "Wheelchair Walk Pace"
        case .wheelchairRunPace: return "Wheelchair Run Pace"
        case .cycling: return "Cycling"
        case .handCycling: return "Hand Cycling"
        case .coreTraining: return "Core Training"
        case .elliptical: return "Elliptical"
        case .functionalStrengthTraining: return "Functional Strength Training"
        case .traditionalStrengthTraining: return "Traditional Strength Training"
        case .crossTraining: return "Cross Training"
        case .mixedCardio: return "Mixed Cardio"
        case .highIntensityIntervalTraining: return "High Intensity Interval Training"
        case .jumpRope: return "Jump Rope"
        case .stairClimbing: return "Stair Climbing"
        case .stairs: return "Stairs"
        case .stepTraining: return "Step Training"
        case .fitnessGaming: return "Fitness Gaming"
        
        // Studio activities
        case .barre: return "Barre"
        case .cardioDance: return "Cardio Dance"
        case .socialDance: return "Social Dance"
        case .yoga: return "Yoga"
        case .mindAndBody: return "Mind and Body"
        case .pilates: return "Pilates"
        
        // Racket sports
        case .badminton: return "Badminton"
        case .pickleball: return "Pickleball"
        case .racquetball: return "Racquetball"
        case .squash: return "Squash"
        case .tableTennis: return "Table Tennis"
        case .tennis: return "Tennis"
        
        // Outdoor activities
        case .climbing: return "Climbing"
        case .equestrianSports: return "Equestrian Sports"
        case .fishing: return "Fishing"
        case .golf: return "Golf"
        case .hiking: return "Hiking"
        case .hunting: return "Hunting"
        case .play: return "Play"
        
        // Snow and ice sports
        case .crossCountrySkiing: return "Cross Country Skiing"
        case .curling: return "Curling"
        case .downhillSkiing: return "Downhill Skiing"
        case .snowSports: return "Snow Sports"
        case .snowboarding: return "Snowboarding"
        case .skatingSports: return "Skating Sports"
        
        // Water activities
        case .paddleSports: return "Paddle Sports"
        case .rowing: return "Rowing"
        case .sailing: return "Sailing"
        case .surfingSports: return "Surfing Sports"
        case .swimming: return "Swimming"
        case .waterFitness: return "Water Fitness"
        case .waterPolo: return "Water Polo"
        case .waterSports: return "Water Sports"
        
        // Martial arts
        case .boxing: return "Boxing"
        case .kickboxing: return "Kickboxing"
        case .martialArts: return "Martial Arts"
        case .taiChi: return "Tai Chi"
        case .wrestling: return "Wrestling"
        
        // Other activities
        case .other: return "Other"
        
        // Deprecated activity types
        case .dance: return "Dance"
        case .danceInspiredTraining: return "Dance Inspired Training"
        case .mixedMetabolicCardioTraining: return "Mixed Metabolic Cardio Training"
        
        // Default
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
    @Published var heartRateGroups: [HKWorkout: [MinutelyHRSample]] = [:]  // Add this line
    @Published var selectedWorkout: HKWorkout? = nil  // add this line
    @Published var sleepHours: Double = 0
    @Published var inBedHours: Double = 0
    @Published var isHeartRateDataLoading: Bool = false

    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    
    init() {
        authorizeHealthKitAccess()
    }
    
    func authorizeHealthKitAccess() {
        let typesToRead = Set([
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)! // New line
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
    
    func getInBedHours() {
        let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples as? [HKCategorySample], error == nil else {
                print("Failed to fetch sleep samples.")
                return
            }
            
            let inBedSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
            let totalInBedTime = inBedSamples.reduce(0) { (accumulated, sample) in
                let endTime = sample.endDate.timeIntervalSinceReferenceDate
                let startTime = sample.startDate.timeIntervalSinceReferenceDate
                return accumulated + (endTime - startTime)
            }
            let totalInBedHours = totalInBedTime / 3600  // convert from seconds to hours
            
            DispatchQueue.main.async {
                self.inBedHours = totalInBedHours
            }
        }
        
        healthStore.execute(query)
    }

    func getSleepHours() {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) { (query, samples, error) in
            if let error = error {
                print("Error occurred while querying for sleep data: \(error.localizedDescription)")
                return
            }
            
            if let sleepSamples = samples as? [HKCategorySample] {
                var sleepTimeSeconds = 0.0
                for sample in sleepSamples {
                    if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                        let duration = sample.endDate.timeIntervalSince(sample.startDate)
                        sleepTimeSeconds += duration
                    }
                }
                
                DispatchQueue.main.async {
                    self.sleepHours = sleepTimeSeconds / 3600 // Convert seconds to hours
                }
            }
        }

        healthStore.execute(query)
    }
    
    func updateHeartRateGroupsFor(workout: HKWorkout) {
        if let heartRates = heartRates[workout] {
            let hrSamples = groupHeartRateSamplesByMinute(heartRates: heartRates)
            heartRateGroups[workout] = hrSamples.map {
                MinutelyHRSample(minute: $0.0, minHR: $0.1.min, maxHR: $0.1.max, avgHR: $0.1.avg)
            }
        }
    }

    func getHeartRateData(for workout: HKWorkout, dispatchGroup: DispatchGroup, completion: @escaping ([HKQuantitySample]) -> Void) {
        dispatchGroup.enter()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
            
            let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                guard let samples = samples as? [HKQuantitySample], error == nil else {
                    print("Failed to fetch heart rate samples for workout \(workout) with error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let hrSamples = self.groupHeartRateSamplesByMinute(heartRates: samples)
                
                DispatchQueue.main.async {
                    self.heartRateGroups[workout] = hrSamples.map { MinutelyHRSample(minute: $0.0, minHR: $0.1.min, maxHR: $0.1.max, avgHR: $0.1.avg) }
                    dispatchGroup.leave()  // Indicate that this task has finished
                }
                completion(samples)
            }
            
            self.isHeartRateDataLoading = true  // Indicate that loading has started
            self.healthStore.execute(heartRateQuery)
        }
    }

    func groupHeartRateSamplesByMinute(heartRates: [HKQuantitySample]) -> [(Date, (min: Int, max: Int, avg: Int))] {
        var groups: [(Date, (min: Int, max: Int, avg: Int))] = []
        var currentGroup: [Double] = []
        var currentMinute: Date? = nil

        for (_, sample) in heartRates.enumerated() {
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
        let startOfDay = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: now)) // Get start of yesterday
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                print("Failed to fetch workouts.")
                return
            }
            
            DispatchQueue.main.async {
                self.workouts = workouts
                
                let dispatchGroup = DispatchGroup()  // Create a DispatchGroup
                
                // Fetch heart rate data for each workout
                workouts.forEach { workout in
                    self.getHeartRateData(for: workout, dispatchGroup: dispatchGroup) { heartRateSamples in
                        self.heartRates[workout] = heartRateSamples
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.isHeartRateDataLoading = false  // Indicate that all heart rate data has finished loading
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
