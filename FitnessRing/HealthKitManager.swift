import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var calories: CGFloat = 0
    
    init() {
        authorizeHealthKitAccess()
    }
    
    func authorizeHealthKitAccess() {
        let typesToRead = Set([HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!])

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { (success, error) in
            if success {
                self.getCalories()
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func getCalories() {
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
                self.calories = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
        }

        healthStore.execute(query)
    }
}
