import SwiftUI
import Combine

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
    @Published var minValue: CGFloat  // Add min value

    init(progress: CGFloat, value: String, keyIcon: ImageIdentifier, keyColor: Color, iconColor: Color, userInput: CGFloat = 0, minValue: CGFloat = 0) {
        self.progress = progress
        self.value = value
        self.keyIcon = keyIcon
        self.keyColor = keyColor
        self.iconColor = iconColor
        self.userInput = userInput
        self.minValue = minValue
    }
}

class RingViewModel: ObservableObject {
    @ObservedObject private var dietManager = DietManager()
    @Published var rings: [Ring]
    private var cancellables: Set<AnyCancellable> = []
    @Published var isLoading = true  // Add this
    
    init() {
        rings = [
            Ring(progress: 0, value: "Completion", keyIcon: .system(name: "line.diagonal.arrow"), keyColor: Color.green, iconColor: Color.green),
            Ring(progress: 0, value: "Calories +/-", keyIcon: .system(name: "flame"), keyColor: Color.red, iconColor: Color.red),
            Ring(progress: 0, value: "Protein", keyIcon: .local(name: "Protein"), keyColor: Color.orange, iconColor: Color.orange),
            Ring(progress: 0, value: "Hydration", keyIcon: .system(name: "drop.fill"), keyColor: Color.blue, iconColor: Color.blue)

        ]
        
        if let userId = UserAuth.getCurrentUserId() {
            dietManager.fetchMinValuesForUser(userId: userId)
        }
        
        dietManager.$minCalories.combineLatest(dietManager.$minProtein, dietManager.$minHydration)
            .sink { [weak self] minCalories, minProtein, minHydration in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.rings[1].minValue = minCalories != 0 ? CGFloat(minCalories) : 0
                    self.rings[2].minValue = minProtein != 0 ? CGFloat(minProtein) : 0
                    self.rings[3].minValue = minHydration != 0 ? CGFloat(minHydration) : 0
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
    
    func updateUserInputForRing(_ ring: Ring, userInput: Float) {
        var minValue: CGFloat = 0
                
        switch ring.value {
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
