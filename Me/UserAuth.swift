import FirebaseAuth
import SwiftUI
import Combine
import FirebaseFirestore

class UserSession: ObservableObject {
    @Published var userId: String? = nil
}

class UserAuth: ObservableObject {
    @Published var isLoggedin: Bool = Auth.auth().currentUser != nil
    @Published var username = ""
    @Published var userSession = UserSession()
    
    init() {
        self.isLoggedin = Auth.auth().currentUser != nil
        fetchUsername()
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            self.isLoggedin = Auth.auth().currentUser != nil
            if let user = Auth.auth().currentUser {
                self.userSession.userId = user.uid
            }
            self.fetchUsername()
        }
    }
    
    func fetchUsername() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists, let data = document.data(), let username = data["username"] as? String {
                self.username = username
            } else if let error = error {
                print("Error fetching username: \(error)")
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
        }
    }
}
