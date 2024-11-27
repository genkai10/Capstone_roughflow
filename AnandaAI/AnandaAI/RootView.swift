// RootView.swift
//import SwiftUI
//
//struct RootView: View {
//    @State private var showSignUpView: Bool = false
//    @State private var showLoginView: Bool = false
//    @State private var isAuthenticated: Bool = false
//
//    var body: some View {
//        NavigationStack {
//            if isAuthenticated {
//                MainTabView() // Navigate to the main view after successful authentication
//            } else {
//                AuthenticationView(showSignUpView: $showSignUpView, showLoginView: $showLoginView)
//            }
//        }
//        .fullScreenCover(isPresented: $showSignUpView) {
//            SignUpView(isAuthenticated: $isAuthenticated)
//                .onDisappear { // Ensures the cover is dismissed
//                    showSignUpView = false
//                }
//        }
//        .fullScreenCover(isPresented: $showLoginView) {
//            LoginView(isAuthenticated: $isAuthenticated)
//                .onDisappear {
//                    showLoginView = false
//                }
//        }
//    }
//}

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var isAuthenticated = Auth.auth().currentUser != nil
    @State private var showSignUpView = false
    @State private var showLoginView = false

    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView(isAuthenticated: $isAuthenticated)
            } else {
                AuthenticationView(showSignUpView: $showSignUpView, showLoginView: $showLoginView, isAuthenticated: $isAuthenticated)
                    .sheet(isPresented: $showSignUpView) {
                        SignUpView(isAuthenticated: $isAuthenticated)
                    }
                    .sheet(isPresented: $showLoginView) {
                        LoginView(isAuthenticated: $isAuthenticated)
                    }
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, user in
                isAuthenticated = (user != nil)
            }
        }
    }
}






