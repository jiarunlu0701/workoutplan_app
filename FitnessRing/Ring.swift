import SwiftUI

enum ImageIdentifier {
    case system(name: String)
    case local(name: String)
}

struct Ring: Identifiable {
    var id = UUID().uuidString
    var progress: CGFloat
    var value: String
    var keyIcon: ImageIdentifier
    var keyColor: Color
    var iconColor: Color
}

var rings: [Ring] = [
    Ring(progress: 36, value: "Overall Progress", keyIcon: .system(name: "line.diagonal.arrow"), keyColor: Color("Green"), iconColor: Color("Green")),
    Ring(progress: 36, value: "Calories +/-", keyIcon: .system(name: "flame"), keyColor: Color("Red"), iconColor: Color("Red")),
    Ring(progress: 50, value: "Protein", keyIcon: .local(name: "Protein"), keyColor: Color("Orange"), iconColor: Color("Orange")),
    Ring(progress: 70, value: "Hydration", keyIcon: .system(name: "drop"), keyColor: Color("Blue"), iconColor: Color("Blue"))
]
