import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI

struct MeView: View {
    @EnvironmentObject var userAuth: UserAuth
    @State private var selectedImage: UIImage?
    @State private var isImagePickerShowing = false
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack {
                if let url = userAuth.userPhotoURL {
                    WebImage(url: url)
                        .resizable()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .onTapGesture {
                            isImagePickerShowing = true
                        }
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            isImagePickerShowing = true
                        }
                }
                Text(userAuth.username)
                    .font(.title)
                
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
        .sheet(isPresented: $isImagePickerShowing) {
            ImagePicker(selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImage) { newValue in
            if let image = newValue {
                userAuth.uploadImage(image: image)
            }
        }
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct MeView_Previews: PreviewProvider {
    static var previews: some View {
        MeView().environmentObject(UserAuth())
    }
}
