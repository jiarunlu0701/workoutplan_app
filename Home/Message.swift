import SwiftUI

struct Message: Codable, Identifiable {
    let id = UUID()
    let role: Role
    let content: String
}

enum Role: String, Codable {
    case user
    case assistant
    case system
}
