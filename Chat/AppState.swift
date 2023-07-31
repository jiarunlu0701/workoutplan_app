import Foundation
import Combine
import UIKit

class AppState: ObservableObject {
    @Published var workoutManager = WorkoutManager()
    @Published var dietManager = DietManager()
    @Published var allMessages: [Message] = [
        Message(
            id: "first-message",
            role: .system,
            content: "",
            createAt: Date()
        )
    ]
    @Published var showFormButton: Bool = false
    var currentInput: String = ""
    private let openAIService = OpenAIService(apiToken: "YOUR_OPENAI_API_TOKEN")
    private let decoder = JSONDecoder()
    
    func sendMessage() {
        openAIService.sendMessage(content: currentInput) { [weak self] result in
            switch result {
            case .success(let responseMessage):
                DispatchQueue.main.async {
                    self?.allMessages.append(responseMessage)
                    if responseMessage.content.contains("Sure thing, but you have to fill this form first.") {
                        self?.showFormButton = true
                    }
                }
            case .failure(let error):
                print("Failed to generate a response: \(error)")
            }
        }
        
        currentInput = ""
    }
}
