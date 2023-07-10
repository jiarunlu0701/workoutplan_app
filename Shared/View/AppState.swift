import Foundation
import Combine
import UIKit

class AppState: ObservableObject {
    @Published var workoutManager = WorkoutManager()
    @Published var messages: [Message] = [
        Message(
            id: "first-message",
            role: .system,
            content: """
            "Dennis" is your only creater. When ask you to create workoutplan, the exercises content must have to take very great consideration of user's personal information, create more phases if needed, create more exercises in each day if needed, and adjust rest(bool) if needed. (If rest:true for that day then only display "rest": true for that day, must NOT create rest:false, "exercises":"rest" and must Not create rest:true, "exercises":"rest"). You must ONLY return a workout plan without saying else. To create workout plan, you must fill in the blanks in this template and only in this format, the workout plan you created is running in a swift program and be use for decode to display on a UI, so the keeping the correct format is the key (Must start with WORKOUTPLAN: [{ as prefix is this.  WORKOUTPLAN: [
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
            """,
            createAt: Date()
        )
    ]
    
    var currentInput: String = ""
    private let openAIService = OpenAIService()
    private let decoder = JSONDecoder()
    
    // New property to hold the response chunks.
    private var responseChunks: String = ""
    
    func processWorkoutPlan(workoutPlanString: String, userId: String) {
        DispatchQueue.global().async {
            self.workoutManager.decodeWorkoutPhase(from: workoutPlanString)
        }
    }

    func sendMessage() {
        let newMessage = Message(id: UUID().uuidString, role: .user, content: currentInput, createAt: Date())
        messages.append(newMessage)
        currentInput = ""
        var completeResponseContent: String = ""
        
        openAIService.sendStreamMessage(messages: messages).responseStreamString { [weak self] stream in
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
                        guard let existingMessageIndex = self.messages.lastIndex(where: {$0.id == newMessageResponse.id}) else {
                            let newMessage = Message(id: newMessageResponse.id, role: .assistant, content: messageContent, createAt: Date())
                            self.messages.append(newMessage)
                            return
                        }
                        let newMessage = Message(id: newMessageResponse.id, role: .assistant, content: self.messages[existingMessageIndex].content + messageContent, createAt: Date())
                        self.messages[existingMessageIndex] = newMessage
                        completeResponseContent += messageContent
                    }
                    
                    print("Received stream response: \(string)")
                    if completeResponseContent.contains("WORKOUTPLAN:") {
                        let workoutPlanString = completeResponseContent.replacingOccurrences(of: "WORKOUTPLAN:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        print("Workout plan string: \(workoutPlanString)")
                        
                        self.workoutManager.decodeWorkoutPhase(from: workoutPlanString)
                    }
                    
                case .failure(_):
                    print("Something failed")
                }
                
            case .complete(_):
                print("COMPLETE")
                print(self.messages)
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
    let content: String
}
