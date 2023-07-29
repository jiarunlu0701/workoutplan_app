import SwiftUI
import HealthKit
import UIKit

struct ContentView: View {
    @State var showView: Bool = false
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var userSession: UserSession

    var body: some View {
        ZStack {
            BackgroundView()
            MainView()
                .environmentObject(userAuth)
                .environmentObject(userSession)
        }
    }
}

struct BackgroundView: View {
    var body: some View {
        ZStack{
            VStack{
                Circle()
                    .fill(Color("Green"))
                    .scaleEffect(0.6)
                    .offset(x: 20)
                    .blur(radius: 120)
                Circle()
                    .fill(Color("Red"))
                    .scaleEffect(0.6,anchor: .leading)
                    .offset(y: -20)
                    .blur(radius: 120)
            }
            Rectangle()
                .fill(.ultraThinMaterial)
        }
        .ignoresSafeArea()
    }
}

struct MainView: View {
    @EnvironmentObject var userAuth: UserAuth
    @StateObject private var appState = AppState()
    @State private var selectedTab: Int = 0
    @State private var lastSelectedTab: Int = 0
    @State private var previousTab: Int = 0
    @State private var showingCoachChat = false
    @StateObject private var ringViewModel = RingViewModel()
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                Home()
                    .environmentObject(userAuth)
                    .tabItem {
                        Image(systemName: "homekit")
                        Text("Home")
                    }.tag(0)
                
                CalendarView(heartRateSamples: healthKitManager.heartRates.values.flatMap { $0 })
                    .environmentObject(ringViewModel)
                    .environmentObject(healthKitManager)
                    .tabItem {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Status")
                    }
                    .tag(2)

                
                BackgroundView()
                    .tabItem {
                        Image(systemName: "message")
                        Text("Coach")
                    }
                    .tag(1)
                
                Text("Coming up soon")
                    .tabItem {
                        Image(systemName: "cart")
                        Text("cart")
                    }.tag(3)

                if userAuth.isLoggedin {
                    MeView()
                        .tabItem {
                            Image(systemName: "person")
                            Text("Me")
                        }.tag(4)
                } else {
                    LoginView()
                        .tabItem {
                            Image(systemName: "person")
                            Text("Me")
                        }.tag(4)
                }
            }
            .onChange(of: selectedTab) { newValue in
                if newValue == 1 {
                    showingCoachChat = true
                }
                previousTab = lastSelectedTab
                lastSelectedTab = newValue
            }
            .fullScreenCover(isPresented: $showingCoachChat, content: {
                CoachChatView(appState: appState, selectedTab: $selectedTab,
                              previousTab: $previousTab)
            })
            
            .environmentObject(appState)
            .onAppear {
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.backgroundColor = UIColor(Color.gray.opacity(0.1))
                UITabBar.appearance().standardAppearance = tabBarAppearance
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
            .accentColor(.black)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(UserAuth())
            .environmentObject(UserSession())
    }
}

