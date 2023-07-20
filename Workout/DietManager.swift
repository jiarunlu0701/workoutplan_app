import Foundation
import FirebaseFirestore
import Firebase

struct DietPlan: Codable, Identifiable {
    var id: String? // Firestore document id
    let date: String
    let total_calories: [String: Float]
    let protein: [String: Float]
    let carbohydrates: [String: Float]
    let hydration: [String: Float]
    let fats: [String: Float]
    let food_sources: [String: [String]]
    let plan_explanation: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case total_calories
        case protein
        case carbohydrates
        case hydration
        case fats
        case food_sources
        case plan_explanation
    }

    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}

class DietManager: ObservableObject {
    @Published var minCalories: Float = 0
    @Published var minProtein: Float = 0
    @Published var minHydration: Float = 0
    @Published var minCarbohydrates: Float = 0
    @Published var dietPlans: [DietPlan] = []
    let db = Firestore.firestore()
    
    func saveDietPlanForUser(userId: String) {
        let userDocument = db.collection("dietPlans").document(userId)
        dietPlans.forEach { dietPlan in
            do {
                let dietPlanDict = try dietPlan.asDictionary()
                userDocument.collection("plans").addDocument(data: dietPlanDict) { error in
                    if let error = error {
                        print("Error saving diet plan: \(error.localizedDescription)")
                    } else {
                        print("Diet plan successfully saved.")
                    }
                }
            } catch {
                print("Error converting diet plan to dictionary: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchDietPlansForUser(userId: String) {
        let userDocument = db.collection("dietPlans").document(userId)
        
        userDocument.collection("plans").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.dietPlans = querySnapshot?.documents.compactMap { queryDocumentSnapshot -> DietPlan? in
                    var data = queryDocumentSnapshot.data()
                    data["id"] = queryDocumentSnapshot.documentID
                    let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
                    if let jsonData = jsonData, let dietPlan = try? JSONDecoder().decode(DietPlan.self, from: jsonData) {
                        return dietPlan
                    } else {
                        return nil
                    }
                } ?? []
            }
        }
    }

    func fetchMinValuesForUser(userId: String) {
        let userDocument = db.collection("dietPlans").document(userId)

        userDocument.collection("plans").getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                querySnapshot?.documents.forEach { queryDocumentSnapshot in
                    var data = queryDocumentSnapshot.data()
                    data["id"] = queryDocumentSnapshot.documentID
                    let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
                    if let jsonData = jsonData, let dietPlan = try? JSONDecoder().decode(DietPlan.self, from: jsonData) {
                        DispatchQueue.main.async {
                            self.minCalories = dietPlan.total_calories["min"] ?? 0
                            self.minProtein = dietPlan.protein["min"] ?? 0
                            self.minHydration = dietPlan.hydration["min"] ?? 0
                            self.minCarbohydrates = dietPlan.carbohydrates["min"] ?? 0  
                        }
                    }
                }
            }
        }
    }


    func decodeDietPlan(from string: String) {
        guard let data = string.data(using: .utf8) else {
            print("Failed to convert string to data.")
            return
        }

        let decoder = JSONDecoder()
        do {
            let dietPlans = try decoder.decode([DietPlan].self, from: data)
            self.dietPlans = dietPlans
        } catch {
            print("Error decoding diet plans: \(error)")
        }
    }
}
