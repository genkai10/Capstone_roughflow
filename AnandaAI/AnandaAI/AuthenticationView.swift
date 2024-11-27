//
//  AuthenticationView.swift
//  AnandaAI
//
//  Created by Diya Maria on 30/10/24.
//

//import SwiftUI
//
//struct AuthenticationView: View {
//    @Binding var showSignInView: Bool
//    @Binding var isAuthenticated: Bool
//
//    var body: some View {
//        VStack {
//            NavigationLink(destination: SignInEmailView(isAuthenticated: $isAuthenticated)) {
//                Text("Sign In with Email")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .frame(height: 55)
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .cornerRadius(10)
//            }
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Sign In")
//    }
//}

// AuthenticationView.swift

import SwiftUI

struct AuthenticationView: View {
    @Binding var showSignUpView: Bool
    @Binding var showLoginView: Bool
    @Binding var isAuthenticated: Bool

    var body: some View {
        VStack {
            Text("Welcome to AnandaAI")
                .font(.title)
            
            Button("Sign Up") {
                showSignUpView = true
            }
            .padding()
            .buttonStyle(.borderedProminent)
            
            Button("Login") {
                showLoginView = true
            }
            .padding()
            .buttonStyle(.borderedProminent)
        }
    }
}

