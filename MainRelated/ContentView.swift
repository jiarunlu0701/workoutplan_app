import SwiftUI
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
    
    var body: some View {
        VStack {
            TabView {
                Home()
                    .environmentObject(userAuth)
                    .tabItem {
                        Image(systemName: "homekit")
                        Text("Home")
                    }
                
                Text("Calendar tb decided")
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("clendar")
                    }
                
                LoginView()
                    .tabItem {
                        Image(systemName: "person")
                        Text("Me")
                    }
            }
            .environmentObject(appState)
            .onAppear {
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.backgroundColor = UIColor(Color.gray.opacity(0.1)) // Replace with your color
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


