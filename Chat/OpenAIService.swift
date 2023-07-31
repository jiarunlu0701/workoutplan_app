import Foundation
import OpenAI
import Combine
import SwiftUI

struct Message: Identifiable, Equatable {
    let id: String
    let role: Role
    let content: String
    let createAt: Date
    
    enum Role: Equatable {
        case user
        case assistant
        case system
    }
}


class OpenAIService {
    @Published var currentInput: String = ""
    @Published var assistantMessages: [Message] = []
    
    private let openAI: OpenAI
    private var cancellables = Set<AnyCancellable>()
    
    init(apiToken: String) {
        self.openAI = OpenAI(apiToken: "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")
    }
    
    func sendMessage(content: String, completion: @escaping (Result<Message, Error>) -> Void) {
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
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("Error: \(error)")
                case .finished:
                    print("Chat stream completed successfully")
                }
            } receiveValue: { result in
                switch result {
                case .success(let chatResult):
                    if let choice = chatResult.choices.first, let assistantResponse = choice.delta.content {
                        let responseMessage = Message(id: UUID().uuidString, role: .assistant, content: assistantResponse, createAt: Date())
                        self.assistantMessages.append(responseMessage)
                        completion(.success(responseMessage))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            .store(in: &cancellables)
    }
}
