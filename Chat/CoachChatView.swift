import SwiftUI

extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CoachChatView: View {
    @ObservedObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userSession: UserSession
    @Binding var selectedTab: Int
    @Binding var previousTab: Int
    private let bottomPaddingID = "BottomPaddingID"
    @State private var isScrolling = false
    
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
                        .onChange(of: appState.allMessages) { _ in
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
                        TextField("Enter a message...", text: $appState.currentInput, onCommit:  {
                            appState.sendMessage()
                            appState.currentInput = ""
                            self.endEditing()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        
                        Button(action: {
                            appState.sendMessage()
                            appState.currentInput = ""
                            self.endEditing()
                        }) {
                            Image(systemName: "paperplane")
                                .resizable()
                                .frame(width: 25, height: 20)
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing)
                    }
                }
            }
        }
    }
    
    func messageView(message: Message) -> some View {
            Group {
                if message.role == .user {
                    HStack {
                        Spacer()
                        Text(message.content)
                            .padding(10)
                            .background(Color.blue)
                            .cornerRadius(15)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                } else if message.role == .assistant {
                    HStack {
                        Text(message.content)
                            .padding(10)
                            .background(Color.green)
                            .cornerRadius(15)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                } else if message.role == .system {
                    Text(message.content)
                        .padding(10)
                        .background(Color.gray)
                        .cornerRadius(15)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                } else {
                    EmptyView()
                }
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
    @State static var selectedTab = 0
    static var previews: some View {
        CoachChatView(appState: AppState(), selectedTab: $selectedTab, previousTab: .constant(0))
    }
}
