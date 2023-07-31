import Foundation
import OpenAI
import Combine
import SwiftUI

struct Message: Identifiable, Equatable {
    let id: String
    let role: Role
    var content: String // Change this line
    let createAt: Date
    
    enum Role: Equatable {
        case user
        case assistant
        case system
    }
}

class OpenAIService {
    @Published var currentInput: String = ""
    @Published var assistantMessages: [Message] = [] // Publish the assistantMessages array
    var currentAssistantMessageId: String? // Add this line
    private let openAI: OpenAI
    private var cancellables = Set<AnyCancellable>()
    private var currentAssistantContent: String = ""
    
    init(apiToken: String) {
        self.openAI = OpenAI(apiToken: "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")
    }
    
    func sendMessage(content: String, completion: @escaping (Result<String, Error>) -> Void) {
        let userMessage = Message(id: UUID().uuidString, role: .user, content: content, createAt: Date())
        assistantMessages.append(userMessage)
        
        var messages: [Chat] = [.init(role: .system, content: "You are a helpful assistant.")]
        messages.append(Chat(role: .user, content: content))
        
        let functions = [
            ChatFunctionDeclaration(
                name: "get_current_weather",
                description: "Get the current weather in a given location",
                parameters: JSONSchema(
                    type: .object,
                    properties: [
                        "location": .init(type: .string, description: "The city and state, e.g. San Francisco, CA"),
                        "unit": .init(type: .string, enumValues: ["celsius", "fahrenheit"])
                    ],
                    required: ["location"]
                )
            )
        ]
        
        let query = ChatQuery(model: .gpt3_5Turbo, messages: messages, functions: functions)
        openAI
            .chatsStream(query: query)
            .sink { [weak self] completionEvent in
                switch completionEvent {
                case .failure(let error):
                    print("Error: \(error)")
                    completion(.failure(error))
                case .finished:
                    print("Chat stream completed successfully")
                }
            } receiveValue: { [weak self] result in
                switch result {
                case .success(let chatResult):
                    if let choice = chatResult.choices.first, let assistantResponse = choice.delta.content {
                        self?.currentAssistantContent.append(assistantResponse)
                        completion(.success(assistantResponse))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            .store(in: &cancellables)
    }
}
