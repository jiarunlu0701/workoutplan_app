import FirebaseAuth
import SwiftUI
import Combine

class UserSession: ObservableObject {
    @Published var userId: String? = nil
}

class UserAuth: ObservableObject {
    @Published var isLoggedin: Bool = Auth.auth().currentUser != nil
    @Published var userSession = UserSession()

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            // Handle errors...
            self?.isLoggedin = Auth.auth().currentUser != nil
            if let user = Auth.auth().currentUser {
                self?.userSession.userId = user.uid
            }
        }
    }
    
    static func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }


    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isLoggedin = false
            self.userSession.userId = nil
        } catch {
            // Handle errors...
        }
    }
}
