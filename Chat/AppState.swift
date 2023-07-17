import Foundation
import Combine
import UIKit

class AppState: ObservableObject {
    @Published var workoutManager = WorkoutManager()
    @Published var conversationMessages: [Message] = [
        Message(
            id: "first-conversation-message",
            role: .system,
            content: "",
            createAt: Date()
        )
    ]
    @Published var workoutMessages: [Message] = [
        Message(
            id: "first-workout-message",
            role: .system,
            content: "",
            createAt: Date()
        )
    ]
    @Published var showFormButton: Bool = false
    
    var currentInput: String = ""
    private let openAIServiceConversation = OpenAIService()
    private let openAIServiceWorkout = OpenAIService()
    private let decoder = JSONDecoder()
    private var responseChunks: String = ""
    
    var allMessages: [Message] {
        return (workoutMessages + conversationMessages).sorted { $0.createAt < $1.createAt }
    }
    
    func processWorkoutPlan(workoutPlanString: String, userId: String) {
        DispatchQueue.global().async {
            self.workoutManager.decodeWorkoutPhase(from: workoutPlanString)
        }
    }
    
    func reset() {
        openAIServiceConversation.cancelCurrentStream()
        openAIServiceWorkout.cancelCurrentStream()
        self.workoutMessages = [
            Message(
                id: "first-message",
                role: .system,
                content: "",
                createAt: Date()
            )
        ]
        self.conversationMessages = [
            Message(
                id: "first-message",
                role: .system,
                content: "",
                createAt: Date()
            )
        ]
        self.currentInput = ""
    }
    
    func sendMessage() {
        let newMessage = Message(id: UUID().uuidString, role: .user, content: currentInput, createAt: Date())
        var completeResponseContent: String = ""
        let currentService: OpenAIService = openAIServiceConversation
        let systemPrompt =  """
        You are a fitness coach, the user is consulting you for fitness advice, talk in a very professional tone.
        
        If the user asked you to create a workout plan, you always have to reply "Sure thing, but you have to fill this form first." You always have to reply this sentence without anymore add-ons because it is the prefix to call the function. If the user ask you about the other stuff related to workout plan, DO not print this sentence at all.
        """
        conversationMessages.append(newMessage)
        
        let systemMessage = Message(id: UUID().uuidString, role: .system, content: systemPrompt, createAt: Date())
        conversationMessages.append(systemMessage)
        
        currentService.sendStreamMessage(messages: conversationMessages).responseStreamString { [weak self] stream in
            guard let self = self else { return }
            switch stream.event {
            case .stream(let response):
                switch response {
                case .success(let string):
                    let streamResponse = self.parseStreamData(string)
                    
                    streamResponse.forEach { newMessageResponse in
                        guard let messageContent = newMessageResponse.choices.first?.delta.content else {
                            return
                        }
                        
                        if let existingMessageIndex = self.conversationMessages.lastIndex(where: {$0.id == newMessageResponse.id}) {
                            let newMessage = Message(id: newMessageResponse.id, role: .assistant, content: self.conversationMessages[existingMessageIndex].content + messageContent, createAt: Date())
                            self.conversationMessages[existingMessageIndex] = newMessage
                            completeResponseContent += messageContent
                        } else {
                            let newMessage = Message(id: newMessageResponse.id, role: .assistant, content: messageContent, createAt: Date())
                            self.conversationMessages.append(newMessage)
                        }
                    }
                    if completeResponseContent.contains("Sure thing, but you have to fill this form first.") {
                        self.showFormButton = true
                    } else {
                        self.showFormButton = false
                    }
                    
                case .failure(_):
                    print("Something failed")
                }
            case .complete(_):
                print("COMPLETE")
                print(self.conversationMessages)
            }
        }
    }
    
    func summarizeWorkoutPlan(workoutPlanDescription: String) {
        let systemPrompt = "You are a fitness assistant. Summarize the following workout plan: \n\(workoutPlanDescription)"
        let systemMessage = Message(id: UUID().uuidString, role: .system, content: systemPrompt, createAt: Date())
        conversationMessages.append(systemMessage)
        var completeResponseContent: String = ""
        
        openAIServiceConversation.sendStreamMessage(messages: conversationMessages).responseStreamString { [weak self] stream in
            guard let self = self else { return }

            switch stream.event {
            case .stream(let response):
                switch response {
                case .success(let string):
                    let streamResponse = self.parseStreamData(string)
                    
                    streamResponse.forEach { newMessageResponse in
                        guard let messageContent = newMessageResponse.choices.first?.delta.content else {
                            return
                        }
                        
                        if let existingMessageIndex = self.conversationMessages.lastIndex(where: {$0.id == newMessageResponse.id}) {
                            let newMessage = Message(id: newMessageResponse.id, role: .assistant, content: self.conversationMessages[existingMessageIndex].content + messageContent, createAt: Date())
                            self.conversationMessages[existingMessageIndex] = newMessage
                            completeResponseContent += messageContent
                        } else {
                            let newMessage = Message(id: newMessageResponse.id, role: .assistant, content: messageContent, createAt: Date())
                            self.conversationMessages.append(newMessage)
                        }
                    }
                    
                case .failure(_):
                    print("Something failed")
                }
                
            case .complete(_):
                print("COMPLETE")
                print(completeResponseContent)
            }
        }
    }



    func generateWorkoutPlan(userMessage: String) {
        let currentService: OpenAIService
        currentService = openAIServiceWorkout
        let systemPrompt = """
            user's Workout Plan Information:"\(userMessage)"
            "When ask you to create workoutplan, the exercises content must have to take very great consideration of user's Workout Plan Information, create more phases if needed, create more exercises in each day if needed, and adjust rest(bool) if needed. (If rest:true for that day then only display "rest": true for that day, must NOT create rest:false, "exercises":"rest" and must Not create rest:true, "exercises":"rest"). You must ONLY return a workout plan without saying else. To create workout plan, you must fill in the blanks in this template and only in this format, the workout plan you created is running in a swift program and be use for decode to display on a UI, so the keeping the correct format is the key (Must start with WORKOUTPLAN: [{ as prefix is this. WORKOUTPLAN: [
            {
                "Phase": str(""),
                "start_date": str("yyyy-mm-dd"),
                "end_date": str("yyyy-mm-dd"),
                "duration_weeks": int(),
                "workouts": [
                    {
                        "day": int(1),
                        "rest": bool(false),
                        "exercises": [
                            {
                                "name": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "notes": str("")
                            }
                        ]
                    },
                    {
                        "day": int(2),
                        "rest": bool(false)
                                    "exercises": [
                                        {
                                            "name": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "notes": str("")
                                        }
                                    ]
                    },
                    {
                        "day": int(3),
                        "rest": bool(false),
                        "exercises": [
                            {
                                "name": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str(“")
                            },
                            {
                                "name": str(""),
                                "sets": int(3),
                                "reps": int(20),
                                "notes": str("")
                            }
                        ]
                    },
                    {
                        "day": int(4),
                        "rest": bool(false)
                        "exercises": [
                                        {
                                            "name": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "notes": str("")
                                        }
                                    ]
                    },
                    {
                        "day": int(5),
                        "rest": bool(false),
                        "exercises": [
                            {
                                "name": str("")
                            },
                            {
                                "name": str("),
                                "sets": int(),
                                "reps": int()
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "notes": str("")
                            }
                        ]
                    },
                    {
                        "day": int(6),
                        "rest": bool(false),
                        "exercises": [
                            {
                                "name": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "suggested_weight": str("")
                            },
                            {
                                "name": str(""),
                                "sets": int(),
                                "reps": int(),
                                "notes": str("")
                            }
                        ]
                    },
                    {
                        "day": int(7),
                        "rest": bool(false)
                        "exercises": [
                                        {
                                            "name": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "suggested_weight": str("")
                                        },
                                        {
                                            "name": str(""),
                                            "sets": int(),
                                            "reps": int(),
                                            "notes": str("")
                                        }
                                    ]
                                    }
                                    ]
                                    }
                                ]
            """
        var completeResponseContent: String = ""

        let systemMessage = Message(id: UUID().uuidString, role: .system, content: systemPrompt, createAt: Date())
        workoutMessages.append(systemMessage)
        
        currentService.sendStreamMessage(messages: workoutMessages).responseStreamString { [weak self] stream in
            guard let self = self else { return }
                        
            switch stream.event {
            case .stream(let response):
                switch response {
                case .success(let string):
                    let streamResponse = self.parseStreamData(string)
                    
                    streamResponse.forEach { newMessageResponse in
                        guard let messageContent = newMessageResponse.choices.first?.delta.content else {
                            return
                        }
                        guard let existingMessageIndex = self.workoutMessages.lastIndex(where: { $0.id == newMessageResponse.id }) else {
                            let newMessage = Message(id: newMessageResponse.id, role: .assistant, content: messageContent, createAt: Date())
                            self.workoutMessages.append(newMessage)
                            return
                        }
                        let newMessage = Message(id: newMessageResponse.id, role: .assistant, content: self.workoutMessages[existingMessageIndex].content + messageContent, createAt: Date())
                        self.workoutMessages[existingMessageIndex] = newMessage
                        completeResponseContent += messageContent
                        print(completeResponseContent)
                    }
                    if completeResponseContent.contains("WORKOUTPLAN:") {
                        let workoutPlanString = completeResponseContent.replacingOccurrences(of: "WORKOUTPLAN:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        self.workoutManager.decodeWorkoutPhase(from: workoutPlanString)
                    }
                case .failure(_):
                    print("Something failed")
                }
                
            case .complete(_):
                print("COMPLETE")
                self.summarizeWorkoutPlan(workoutPlanDescription: completeResponseContent)
                if let userId = UserAuth.getCurrentUserId() {
                    self.workoutManager.saveWorkoutPhasesForUser(userId: userId)
                } else {
                    print("No user is currently signed in.")
                }
            }
        }
    }
    
    func parseStreamData(_ data: String) -> [ChatStreamCompletionResponse] {
        let responseStrings = data.split(separator: "data:").map({$0.trimmingCharacters(in: .whitespacesAndNewlines)}).filter({!$0.isEmpty})
        let jsonDecoder = JSONDecoder()
        
        return responseStrings.compactMap { jsonString in
            guard let jsonData = jsonString.data(using: .utf8), let streamResponse = try? jsonDecoder.decode(ChatStreamCompletionResponse.self, from: jsonData) else {
                return nil
            }
            return streamResponse
        }
    }
}

struct Message: Identifiable, Decodable, Hashable {
    let id: String
    let role: SenderRole
    var content: String
    let createAt: Date
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    func copyTextToClipboard() {
        let pasteboard = UIPasteboard.general
        pasteboard.string = content
    }
}

struct ChatStreamCompletionResponse: Decodable {
    let id: String
    let choices: [ChatStreamChoice]
}

struct ChatStreamChoice: Decodable {
    let delta: ChatStreamContent
}

struct ChatStreamContent: Decodable {
    let content: String}
