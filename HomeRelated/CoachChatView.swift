import SwiftUI

struct CoachChatView: View {
    @ObservedObject var appState: AppState
    let decoder = JSONDecoder()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userSession: UserSession
    @Binding var selectedTab: Int  // Add this line
    private let bottomPaddingID = "BottomPaddingID"
    @State private var isScrolling = false // Track scrolling state

    var body: some View {
        ZStack {
            BackgroundView()
            VStack {
                // Close button
                HStack(alignment: .center) {
                    Spacer()
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                        self.selectedTab = 0 // change this to the index of the tab you want to display
                    }) {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                }
                .padding()

                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(appState.messages.filter({$0.role != .system}), id: \.self.id) { message in
                            messageView(message: message)
                                .id(message.id)
                        }
                        Color.clear.frame(height: 1)
                            .id(bottomPaddingID)
                    }
                    .onAppear {
                        proxy.scrollTo(bottomPaddingID)
                    }
                    .onChange(of: appState.messages) { _ in
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
                    }) {
                        Text("Send")
                    }
                }
                .padding()
            }
        }
    }

    func messageView(message: Message) -> some View {
        HStack {
            if message.role == .user { Spacer() }
            Text(message.content)
                .padding()
                .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(20)
                .contextMenu {
                    Button(action: {
                        message.copyTextToClipboard()
                        // Optionally show some sort of feedback that the text has been copied
                        print("Text copied to clipboard")
                    }) {
                        Text("Copy")
                        Image(systemName: "doc.on.doc")
                    }
                }
            if message.role == .assistant { Spacer() }
        }
    }
    
    func scrollToBottom(_ proxy: ScrollViewProxy) {
        proxy.scrollTo(bottomPaddingID, anchor: .bottom)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isScrolling = false
        }
    }
}

struct CoachChatView_Previews: PreviewProvider {
    @State static var selectedTab = 0 // Add this line
    static var previews: some View {
        NavigationView {
            CoachChatView(appState: AppState(), selectedTab: $selectedTab)
        }
    }
}
