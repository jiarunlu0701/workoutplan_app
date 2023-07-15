import SwiftUI
import Combine

class ViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    
    private let messagesKey = "MessageHistory"
    
    init() {
        loadMessageHistory()
    }
    
    func sendMessage() {
        let newMessage = Message(role: .user, content: currentInput)
        messages.append(newMessage)
        
        saveMessageHistory()
        
        currentInput = ""
    }
    
    private func saveMessageHistory() {
        do {
            let encoder = JSONEncoder()
            let encodedMessages = try encoder.encode(messages)
            
            UserDefaults.standard.set(encodedMessages, forKey: messagesKey)
        } catch {
            print("Error saving message history: \(error.localizedDescription)")
        }
    }
    
    private func loadMessageHistory() {
        guard let encodedMessages = UserDefaults.standard.data(forKey: messagesKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let decodedMessages = try decoder.decode([Message].self, from: encodedMessages)
            
            messages = decodedMessages
        } catch {
            print("Error loading message history: \(error.localizedDescription)")
        }
    }
}
