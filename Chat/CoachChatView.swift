import SwiftUI

extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CoachChatView: View {
    @ObservedObject var appState: AppState
    private let openAIService = OpenAIService()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userSession: UserSession
    @Binding var selectedTab: Int
    @Binding var previousTab: Int
    private let bottomPaddingID = "BottomPaddingID"
    @State private var isScrolling = false
    @State private var showFormIcon: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                VStack {
                    HStack {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                            self.selectedTab = self.previousTab
                        }) {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            self.resetAppState()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()

                    ScrollViewReader {proxy in
                        ScrollView {
                            ForEach(appState.allMessages.filter({$0.role != .system}), id: \.self.id) { message in
                                messageView(message: message)
                                    .id(message.id)
                            }
                            Color.clear.frame(height: 1)
                                .id(bottomPaddingID)
                        }
                        .onAppear {
                            proxy.scrollTo(bottomPaddingID)
                        }
                        .onChange(of: allMessages()) { _ in
                            DispatchQueue.main.async {
                                withAnimation {
                                    if !isScrolling {
                                        isScrolling = true
                                        scrollToBottom(proxy)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    
                    HStack {
                        TextField("Enter a message...", text: $appState.currentInput)
                        Button(action: {
                            appState.sendMessage()
                            appState.currentInput = ""
                            self.endEditing()
                        }) {
                            Image(systemName: "paperplane")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    func messageView(message: Message) -> some View {
        VStack {
            HStack {
                if message.role == .user { Spacer() }
                Text(message.content)
                    .padding()
                    .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    .contextMenu {
                        Button(action: {
                            message.copyTextToClipboard()
                            print("Text copied to clipboard")
                        }) {
                            Text("Copy")
                            Image(systemName: "doc.on.doc")
                        }
                    }
                if message.role == .assistant { Spacer() }
            }
            if message.content == "Sure thing, but you have to fill this form first." {
                NavigationLink(destination: WorkoutPlanForm()) {
                    Image(systemName: "doc")
                        .resizable()
                        .frame(width: 45, height: 60)
                        .foregroundColor(.gray)
                }
            }
        }
    }



    func allMessages() -> [Message] {
        return (appState.workoutMessages + appState.conversationMessages)
            .sorted(by: {$0.createAt < $1.createAt})
    }
    
    func scrollToBottom(_ proxy: ScrollViewProxy) {
        proxy.scrollTo(bottomPaddingID, anchor: .bottom)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isScrolling = false
        }
    }
    
    func resetAppState() {
        openAIService.cancelCurrentStream()
        self.appState.reset()
    }
}

struct CoachChatView_Previews: PreviewProvider {
    @State static var selectedTab = 0
    static var previews: some View {
        CoachChatView(appState: AppState(), selectedTab: $selectedTab, previousTab: .constant(0))
    }
}
