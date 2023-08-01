import Foundation
import Combine
import UIKit

class ObservableMessage: ObservableObject {
    @Published var message: Message

    init(message: Message) {
        self.message = message
    }
}

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
    private var newResponsePending: Bool = false
    private let openAIService: OpenAIService
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.openAIService = OpenAIService(apiToken: "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")
        openAIService.$assistantMessages
            .sink { [weak self] newMessages in
                DispatchQueue.main.async {
                    // Only append messages that are not already in allMessages
                    let newOnly = newMessages.filter { self?.allMessages.contains($0) == false }
                    self?.allMessages.append(contentsOf: newOnly)
                }
            }
            .store(in: &cancellables)
    }
    
    func sendMessage() {
        let userInputMessage = Message(id: UUID().uuidString, role: .user, content: currentInput, createAt: Date())
        allMessages.append(userInputMessage)
        newResponsePending = true
        
        openAIService.sendMessage(content: currentInput) { [weak self] result in
            switch result {
            case .success(let chunk):
                DispatchQueue.main.async {
                    if self?.newResponsePending ?? false {
                        let newAssistantMessage = Message(id: UUID().uuidString, role: .assistant, content: chunk, createAt: Date())
                        self?.allMessages.append(newAssistantMessage)
                        self?.newResponsePending = false
                    } else {
                        if let index = self?.allMessages.lastIndex(where: { $0.role == .assistant }) {
                            let lastAssistantMessage = self?.allMessages[index]
                            let updatedAssistantMessage = Message(id: lastAssistantMessage?.id ?? "", role: .assistant, content: (lastAssistantMessage?.content ?? "") + chunk, createAt: lastAssistantMessage?.createAt ?? Date())
                            self?.allMessages[index] = updatedAssistantMessage
                        } else {
                            let message = Message(id: UUID().uuidString, role: .assistant, content: chunk, createAt: Date())
                            self?.allMessages.append(message)
                        }
                    }
                }
            case .failure(let error):
                print("Failed to generate a response: \(error)")
            }
        }
        currentInput = ""
    }
}
