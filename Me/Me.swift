import SwiftUI
import FirebaseAuth


struct MeView: View{
    @EnvironmentObject var userAuth: UserAuth
    
    var body: some View {
        ZStack{
            BackgroundView()
            VStack{
                HStack(){
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.gray)
                    Text(userAuth.username)
                        .font(.title)
                }
                Button(action: {
                    userAuth.signOut()
                }) {
                    Text("Sign Out")
                        .fontWeight(.bold)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                Spacer()
            }
        }
    }
}

struct MeView_Previews: PreviewProvider {
    static var previews: some View {
        MeView().environmentObject(UserAuth())
    }
}
