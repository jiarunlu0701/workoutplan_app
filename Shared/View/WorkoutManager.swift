import Foundation
import FirebaseFirestore
import Firebase

struct Exercise: Codable, Identifiable {
    let id = UUID()
    let name: String
    let sets: Int?
    let reps: Int?
    let suggested_weight: String?
    let notes: String?
}

struct Workout: Codable, Identifiable {
    let id = UUID()
    let day: Int
    let exercises: [Exercise]?
    let rest: Bool?
}

struct WorkoutPhase: Codable, Identifiable {
    let id = UUID()
    let Phase: String
    let workouts: [Workout]
    let start_date: String
    let end_date: String
    let duration_weeks: Int
}

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}

class WorkoutManager: ObservableObject {
    @Published var workoutPhases: [WorkoutPhase] = []
    let db = Firestore.firestore()
    
    func saveWorkoutPhasesForUser(userId: String) {
        let userDocument = db.collection("workoutPhases").document(userId)
        workoutPhases.forEach {workoutPhase in
            do {
                let workoutPhaseDict = try workoutPhase.asDictionary()
                userDocument.collection("phases").addDocument(data: workoutPhaseDict) { error in
                    if let error = error {
                        print("Error saving workout phase: \(error.localizedDescription)")
                    } else {
                        print("Workout phase successfully saved.")
                    }
                }
            } catch {
                print("Error converting workout phase to dictionary: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchWorkoutPhasesForUser(userId: String) {
        let userDocument = db.collection("workoutPhases").document(userId)
        
        userDocument.collection("phases").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.workoutPhases = querySnapshot?.documents.compactMap { queryDocumentSnapshot -> WorkoutPhase? in
                    let data = try? JSONSerialization.data(withJSONObject: queryDocumentSnapshot.data(), options: [])
                    if let data = data, let workoutPhase = try? JSONDecoder().decode(WorkoutPhase.self, from: data) {
                        return workoutPhase
                    } else {
                        return nil
                    }
                } ?? []
            }
        }
    }
    
    func exercisesForDay(date: Date) -> [Exercise] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let filteredPhases = workoutPhases.filter { phase in
            if let phaseStartDate = dateFormatter.date(from: phase.start_date),
               let phaseEndDate = dateFormatter.date(from: phase.end_date) {
                return phaseStartDate...phaseEndDate ~= date
            }
            return false
        }
        let filteredWorkouts = filteredPhases.flatMap { phase in
            let weekday = calendar.component(.weekday, from: date)
            let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
            return phase.workouts.filter { workout in
                return workout.day == adjustedWeekday
            }
        }
        return filteredWorkouts.flatMap { $0.exercises ?? [] }
    }
    
    func decodeWorkoutPhase(from string: String) {
        guard let data = string.data(using: .utf8) else {
            print("Failed to convert string to data.")
            return
        }

        let decoder = JSONDecoder()
        do {
            let workoutPhases = try decoder.decode([WorkoutPhase].self, from: data)
            self.workoutPhases = workoutPhases // Updating workoutPhases with decoded data
        } catch {
            if let decodingError = error as? DecodingError {
                print("DecodingError: \(decodingError)")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("Failed to decode due to type mismatch: \(type)")
                    print("Debug description: \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("Failed to decode due to value not found: \(type)")
                    print("Debug description: \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("Failed to decode due to key not found: \(key.stringValue)")
                    print("Debug description: \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("Failed to decode due to data corrupted: \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                @unknown default:
                    print("Unknown decoding error")
                }
            } else {
                print("Error decoding workout phases: \(error)")
            }
        }
    }

    var earliestPhaseStartDate: Date {
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = "yyyy-MM-dd"
           return workoutPhases.compactMap { dateFormatter.date(from: $0.start_date) }.min() ?? Date()
       }

    var latestPhaseEndDate: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return workoutPhases.compactMap { dateFormatter.date(from: $0.end_date) }.max() ?? Date()
    }
}
