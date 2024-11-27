import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class SignUpViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isError = false
    @Published var errorMessage = ""
}

struct SignUpView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var viewModel = SignUpViewModel()
    @State private var navigateToMainTabView = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Create Account")
                    .font(.title)

                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button("Sign Up") {
                    signUpUser()
                }
                .buttonStyle(.borderedProminent)
                .padding()

                if viewModel.isError {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding(.top)
                }

                // Hidden NavigationLink to navigate programmatically
                NavigationLink(destination: MainTabView(isAuthenticated: $isAuthenticated), isActive: $navigateToMainTabView) {
                    EmptyView()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Sign Up")
            .onChange(of: isAuthenticated) { authenticated in
                if authenticated {
                    navigateToMainTabView = true
                }
            }
        }
    }

    private func signUpUser() {
        Auth.auth().createUser(withEmail: viewModel.email, password: viewModel.password) { authResult, error in
            if let error = error {
                viewModel.isError = true
                viewModel.errorMessage = error.localizedDescription
                return
            }

            // Save user profile if sign-up is successful
            guard let userID = authResult?.user.uid else { return }
            saveUserProfile(userID: userID, username: viewModel.username, email: viewModel.email)
            
            // Mark as authenticated to navigate to MainTabView
            isAuthenticated = true
        }
    }

    // Function to save profile details to Firestore
    private func saveUserProfile(userID: String, username: String, email: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).setData([
            "username": username,
            "email": email,
            "medications": []  // Initial empty medications array
        ]) { error in
            if let error = error {
                viewModel.isError = true
                viewModel.errorMessage = "Failed to save profile data: \(error.localizedDescription)"
            }
        }
    }
}

