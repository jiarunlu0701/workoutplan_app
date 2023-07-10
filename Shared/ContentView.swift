import SwiftUI

struct ContentView: View {
    @State var showView: Bool = false
    @EnvironmentObject var userAuth: UserAuth
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    if userAuth.isLoggedin {
                        Home()
                    } else {
                        LoginView()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.clear)
        }
        .preferredColorScheme(.dark)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(UserAuth())
    }
}

