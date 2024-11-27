import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isError = false
    @Published var errorMessage = ""
}

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var viewModel = LoginViewModel()
    @State private var navigateToMainTabView = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Log In")
                    .font(.title)

                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button("Log In") {
                    loginUser()
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
            .navigationTitle("Log In")
            .onChange(of: isAuthenticated) { authenticated in
                if authenticated {
                    navigateToMainTabView = true
                }
            }
        }
    }

    private func loginUser() {
        Auth.auth().signIn(withEmail: viewModel.email, password: viewModel.password) { authResult, error in
            if let error = error {
                viewModel.isError = true
                viewModel.errorMessage = error.localizedDescription
                return
            }
            
            // Mark as authenticated to navigate to MainTabView
            isAuthenticated = true
        }
    }
}
