import SwiftUI

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

    init(progress: CGFloat, value: String, keyIcon: ImageIdentifier, keyColor: Color, iconColor: Color) {
        self.progress = progress
        self.value = value
        self.keyIcon = keyIcon
        self.keyColor = keyColor
        self.iconColor = iconColor
    }
}

class RingViewModel: ObservableObject {
    @Published var rings: [Ring] = [
        Ring(progress: 36, value: "Completion", keyIcon: .system(name: "line.diagonal.arrow"), keyColor: Color.green, iconColor: Color.green),
        Ring(progress: 36, value: "Calories +/-", keyIcon: .system(name: "flame"), keyColor: Color.red, iconColor: Color.red),
        Ring(progress: 50, value: "Protein", keyIcon: .local(name: "Protein"), keyColor: Color.orange, iconColor: Color.orange),
        Ring(progress: 70, value: "Hydration", keyIcon: .system(name: "drop.fill"), keyColor: Color.blue, iconColor: Color.blue)
    ]
}
