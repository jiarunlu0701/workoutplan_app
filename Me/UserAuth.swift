import FirebaseAuth
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseStorage

class UserSession: ObservableObject {
    @Published var userId: String? = nil
}

class UserAuth: ObservableObject {
    @Published var isLoggedin: Bool = Auth.auth().currentUser != nil
    @Published var username = ""
    @Published var userPhotoURL: URL?
    @Published var selectedImage = UIImage()
    @Published var userSession = UserSession()
    
    init() {
        self.isLoggedin = Auth.auth().currentUser != nil
        fetchUsernameAndPhoto()
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            self.isLoggedin = Auth.auth().currentUser != nil
            if let user = Auth.auth().currentUser {
                self.userSession.userId = user.uid
            }
            self.fetchUsernameAndPhoto()
        }
    }
    
    func uploadImage(image: UIImage) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("user_images/\(userID).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error)")
            } else {
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download url: \(error)")
                    } else if let url = url {
                        let db = Firestore.firestore()
                        db.collection("users").document(userID).updateData(["photoURL": url.absoluteString]) { error in
                            if let error = error {
                                print("Error saving user photo url to Firestore: \(error)")
                            } else {
                                self.userPhotoURL = url
                            }
                        }
                    }
                }
            }
        }
    }

    func fetchUsernameAndPhoto() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                if let username = data["username"] as? String {
                    self.username = username
                }
                if let photoURLString = data["photoURL"] as? String,
                   let photoURL = URL(string: photoURLString) {
                    self.userPhotoURL = photoURL
                }
            } else if let error = error {
                print("Error fetching username and photo: \(error)")
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
