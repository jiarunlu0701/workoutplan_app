import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorText = ""
    @State private var showingSignUp = false
    @EnvironmentObject var userAuth: UserAuth

    var body: some View {
        VStack {
            Text("Login")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            if !errorText.isEmpty {
                Text(errorText)
                    .font(.callout)
                    .foregroundColor(.red)
                    .padding(.bottom, 20)
            }
            
            Button(action: { loginUser() }) {
                Text("Login")
                    .fontWeight(.bold)
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }

            Button(action: { showingSignUp = true }) {
                Text("Sign Up")
                    .fontWeight(.bold)
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView(isPresented: $showingSignUp)
            }
        }
        .padding(.horizontal)
    }
    
    private func loginUser() {
        userAuth.signIn(email: email, password: password)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(UserAuth())
    }
}

