import OpenAI
import Combine
import SwiftUI

struct FunctionCall: Codable {
    let name: String
    let arguments: String
}

struct Message: Identifiable, Equatable {
    let id: String
    let role: Chat.Role
    var content: String
    
    let createAt: Date
}

class OpenAIService {
    @Published var currentInput: String = ""
    @Published var assistantMessages: [Message] = []
    var currentAssistantMessageId: String?
    private let openAI: OpenAI
    private var cancellables = Set<AnyCancellable>()
    private var currentAssistantContent: String = ""
    private var currentFunctionName: String = ""
    private var currentFunctionArguments: String = ""
    private var currentFunctionDetails: String = ""

    init(apiToken: String) {
        self.openAI = OpenAI(apiToken: "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")
    }
    
    func sendMessage(content: String, completion: @escaping (Result<String, Error>) -> Void) {
        let userMessage = Message(id: UUID().uuidString, role: .user, content: content, createAt: Date())
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
                    if let choice = chatResult.choices.first {
                        if let assistantResponse = choice.delta.content {
                            self?.currentAssistantContent.append(assistantResponse)
                            completion(.success(assistantResponse))
                        }
                        if let functionCall = choice.delta.functionCall {
                                                    // Store function name if it's not stored yet
                                                    if self?.currentFunctionName.isEmpty ?? true {
                                                        self?.currentFunctionName = functionCall.name ?? ""
                                                    }
                                                    
                                                    self?.currentFunctionDetails.append(functionCall.arguments ?? "")
                                                    
                                                    if self?.currentFunctionDetails.last == "}" {
                                                        // Assuming you have the full JSON string here
                                                        let functionCallMessage = Message(id: UUID().uuidString, role: .assistant,
                                                                                          content: "Function: \(self?.currentFunctionName ?? "")\nParameter: \(self?.currentFunctionDetails ?? "")",
                                                                                          createAt: Date())

                                                        print(functionCallMessage)
                                                        self?.assistantMessages.append(functionCallMessage)
                                                        // Reset for the next function call
                                                        self?.currentFunctionDetails = ""
                                                        self?.currentFunctionName = ""
                                                    }
                                                }
                                            }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            .store(in: &cancellables)
    }
}
