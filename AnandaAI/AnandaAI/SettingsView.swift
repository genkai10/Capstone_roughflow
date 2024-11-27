import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .padding(.top, 50)

            Button("Log Out") {
                logOutUser()
            }
            .buttonStyle(.bordered)
            .padding()
            
            Spacer()
        }
        .padding()
    }

    private func logOutUser() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false  // Update authentication state to show login view
        } catch let error {
            print("Error logging out: \(error.localizedDescription)")
        }
    }
}
