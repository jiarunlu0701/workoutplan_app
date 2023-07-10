import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirm_password = ""
    @State private var errorText = ""
    @EnvironmentObject var userAuth: UserAuth
    @Binding var isPresented: Bool
    var body: some View {
        ZStack{
            BackgroundView()
            VStack {
                
                Text("Sign Up")
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
                
                SecureField("Confirm Password", text: $confirm_password)
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
                
                Button(action: { signUpUser() }) {
                    Text("Sign Up")
                        .fontWeight(.bold)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
        
    }
    
    private func signUpUser() {
        guard password == confirm_password else {
            errorText = "Passwords do not match."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorText = error.localizedDescription
            } else {
                self.userAuth.signIn(email: self.email, password: self.password)

            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(isPresented: .constant(true)).environmentObject(UserAuth())
    }
}
