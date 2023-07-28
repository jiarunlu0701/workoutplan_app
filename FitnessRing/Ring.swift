import SwiftUI
import Combine
import Firebase
import FirebaseFirestore

enum ImageIdentifier {
    case system(name: String)
    case local(name: String)
}

class Ring: Identifiable, ObservableObject {
    var id = UUID().uuidString
    @Published var progress: CGFloat
    var value: String
    var keyIcon: ImageIdentifier
    var keyColor: Color
    var iconColor: Color
    @Published var userInput: CGFloat
    @Published var minValue: CGFloat
    var lastUpdatedDate: Date?  // New property

    init(progress: CGFloat, value: String, keyIcon: ImageIdentifier, keyColor: Color, iconColor: Color, userInput: CGFloat = 0, minValue: CGFloat = 0, lastUpdatedDate: Date? = nil) {
        self.progress = progress
        self.value = value
        self.keyIcon = keyIcon
        self.keyColor = keyColor
        self.iconColor = iconColor
        self.userInput = userInput
        self.minValue = minValue
        self.lastUpdatedDate = lastUpdatedDate  // Now it's valid
    }
}


class RingViewModel: ObservableObject {
    @ObservedObject private var dietManager = DietManager()
    @Published var needsRefresh: Bool = false
    @Published var userAuth = UserAuth() {
        didSet {
            loadData()
        }
    }
    @Published var rings: [Ring]
    private var cancellables: Set<AnyCancellable> = []
    @Published var fetchedUserInputs: [Ring] = []
    @Published var isLoading = true
    @Published var isDataLoaded = false

    init() {
        rings = [
            Ring(progress: 0, value: "Carbohydrates", keyIcon: .system(name: "bolt"), keyColor: Color.green, iconColor: Color.green),
            Ring(progress: 0, value: "Calories +/-", keyIcon: .system(name: "flame"), keyColor: Color.red, iconColor: Color.red),
            Ring(progress: 0, value: "Protein", keyIcon: .local(name: "Protein"), keyColor: Color.orange, iconColor: Color.orange),
            Ring(progress: 0, value: "Hydration", keyIcon: .system(name: "drop.fill"), keyColor: Color.blue, iconColor: Color.blue)
        ]

        if let userId = UserAuth.getCurrentUserId() {
            dietManager.fetchMinValuesForUser(userId: userId)
        }
        
        dietManager.$minCalories.combineLatest(dietManager.$minProtein, dietManager.$minHydration, dietManager.$minCarbohydrates)
            .sink { [weak self] minCalories, minProtein, minHydration, minCarbohydrates in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.rings[0].minValue = minCarbohydrates != 0 ? CGFloat(minCarbohydrates) : 0
                    self.rings[1].minValue = minCalories != 0 ? CGFloat(minCalories) : 0
                    self.rings[2].minValue = minProtein != 0 ? CGFloat(minProtein) : 0
                    self.rings[3].minValue = minHydration != 0 ? CGFloat(minHydration) : 0
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)

        fetchUserInputsFromFirestore()
        
        userAuth.$isLoggedin
            .sink { isLoggedIn in
                DispatchQueue.main.async {
                    self.loadData()
                }
            }
            .store(in: &cancellables)
        NotificationCenter.default.addObserver(self, selector: #selector(userLoggedIn), name: NSNotification.Name("UserLoggedIn"), object: nil)
    }
    
    @objc func userLoggedIn() {
        self.needsRefresh = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadData() {
        if let userId = UserAuth.getCurrentUserId() {
            dietManager.fetchMinValuesForUser(userId: userId)
            fetchUserInputsFromFirestore()
        } else {
            for ring in rings {
                ring.userInput = 0
                ring.progress = 0
                ring.minValue = 0
            }
            isLoading = false
            isDataLoaded = true
        }
    }

    func storeUserInputInFirestore(ring: Ring) {
        let db = Firestore.firestore()

        guard let userId = UserAuth.getCurrentUserId() else {
            return
        }

        // Create a date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Convert current date to string
        let dateString = dateFormatter.string(from: Date())

        // Create a document for each date and each ring value
        // Replace any special characters and whitespace in the ring value
        let sanitizedRingValue = ring.value.replacingOccurrences(of: "[^0-9a-zA-Z]", with: "_", options: .regularExpression)
        db.collection("rings").document(userId).collection("userInput").document("\(dateString)_\(sanitizedRingValue)").setData([
            "ringId": ring.id,
            "value": ring.value,
            "userInput": ring.userInput,
            "lastUpdatedDate": Date()
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added with ID: \(ring.id)")
            }
        }
    }
    
    func fetchUserInputsFromFirestore() {
        let db = Firestore.firestore()

        guard let userId = UserAuth.getCurrentUserId() else {
            return
        }

        let calendar = Calendar.current
        // Get the start of the current day
        let startOfDay = calendar.startOfDay(for: Date())
        let startOfDayTimestamp = Timestamp(date: startOfDay)

        db.collection("rings").document(userId).collection("userInput").whereField("lastUpdatedDate", isGreaterThanOrEqualTo: startOfDayTimestamp).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.fetchedUserInputs = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    if let value = data["value"] as? String,
                       let userInput = data["userInput"] as? CGFloat,
                       let lastUpdatedTimestamp = data["lastUpdatedDate"] as? Timestamp {
                        let lastUpdatedDate = lastUpdatedTimestamp.dateValue() // Convert Timestamp to Date
                        return Ring(progress: 0, value: value, keyIcon: .system(name: "circle"), keyColor: .white, iconColor: .white, userInput: userInput, minValue: 0, lastUpdatedDate: lastUpdatedDate)
                    } else {
                        return nil // This line is now valid
                    }
                } ?? []
                self.updateRingsWithFetchedUserInputs()
                self.isDataLoaded = true
            }
        }
    }

    func updateRingsWithFetchedUserInputs() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for fetchedRing in fetchedUserInputs {
            if let index = rings.firstIndex(where: { $0.value == fetchedRing.value }) {
                if let lastUpdatedDate = fetchedRing.lastUpdatedDate, calendar.startOfDay(for: lastUpdatedDate) == today {
                    rings[index].userInput = fetchedRing.userInput
                    let percentage = (CGFloat(rings[index].userInput) / rings[index].minValue) * 100
                    rings[index].progress = rings[index].minValue != 0 ? percentage : 0
                } else {
                    rings[index].userInput = 0
                    rings[index].progress = 0
                }
                rings[index].lastUpdatedDate = fetchedRing.lastUpdatedDate
            }
        }
    }

    func updateUserInputForRing(_ ring: Ring, userInput: Float) {
        var minValue: CGFloat = 0
                
        switch ring.value {
        case "Carbohydrates":
            minValue = CGFloat(dietManager.minCarbohydrates)
        case "Calories +/-":
            minValue = CGFloat(dietManager.minCalories)
        case "Protein":
            minValue = CGFloat(dietManager.minProtein)
        case "Hydration":
            minValue = CGFloat(dietManager.minHydration)
        default:
            break
        }

        ring.userInput = CGFloat(userInput)
        let percentage = (CGFloat(userInput) / minValue) * 100
        ring.progress = minValue != 0 ? percentage : 0
        ring.minValue = minValue
        rings.append(Ring(progress: 0, value: "Force Update", keyIcon: .system(name: "circle"), keyColor: Color.white, iconColor: Color.white))
        rings.removeLast()
    }
}
