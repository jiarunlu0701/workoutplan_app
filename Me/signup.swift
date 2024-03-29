import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email = ""
    @State private var username = ""
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
                
                TextField("User Name", text: $username)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .frame(width:350)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .frame(width:350)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .frame(width:350)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                SecureField("Confirm Password", text: $confirm_password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .frame(width:350)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                if !errorText.isEmpty {
                    Text(errorText)
                        .font(.callout)
                        .foregroundColor(.red)
                        .padding(.bottom, 20)
                }
                
                Button(action: {signUpUser() }) {
                    Text("Sign Up")
                        .fontWeight(.bold)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }
        }
    }
    
    private func signUpUser() {
        guard password == confirm_password else {
            errorText = "Passwords do not match."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorText = error.localizedDescription
            } else if let result = result {
                let db = Firestore.firestore()
                db.collection("users").document(result.user.uid).setData(["username": self.username]) { error in
                    if let error = error {
                        print("Error saving user to Firestore: \(error)")
                    } else {
                        self.userAuth.username = self.username
                        self.userAuth.signIn(email: self.email, password: self.password)
                        self.isPresented = false
                    }
                }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(isPresented: .constant(true)).environmentObject(UserAuth())
    }
}
