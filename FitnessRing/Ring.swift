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
    @Published var userInput: CGFloat  // User input value

    init(progress: CGFloat, value: String, keyIcon: ImageIdentifier, keyColor: Color, iconColor: Color, userInput: CGFloat = 0) {
        self.progress = progress
        self.value = value
        self.keyIcon = keyIcon
        self.keyColor = keyColor
        self.iconColor = iconColor
        self.userInput = userInput
    }
}

class RingViewModel: ObservableObject {
    @ObservedObject private var dietManager = DietManager()
    @Published var rings: [Ring]
    private var cancellables: Set<AnyCancellable> = []
    
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
                
                self.rings[1].progress = minCalories != 0 ?  CGFloat(minCalories) : 0
                self.rings[2].progress = minProtein != 0 ? CGFloat(minProtein) : 0
                self.rings[3].progress = minHydration != 0 ? CGFloat(minHydration) : 0
            }
            .store(in: &cancellables)
    }
    
    func updateUserInputForRing(_ ring: Ring, userInput: CGFloat) {
        ring.userInput = userInput
    }
}
