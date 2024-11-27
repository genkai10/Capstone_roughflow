//
//  MainTabView.swift
//  AnandaAI
//
//  Created by Diya Maria on 31/10/24.
//

// MainTabView.swift

import SwiftUI

struct MainTabView: View {
    @Binding var isAuthenticated: Bool
    var body: some View {
        TabView {
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            
            AccelerometerView()
                .tabItem {
                    Label("Accelerometer", systemImage: "waveform.path.ecg")
                }
            
            VideoView() // Add the VideoView tab
                .tabItem {
                    Label("Video", systemImage: "video.fill")
                }
            
            VitalSignsView() // Add the new Vital Signs tab
                .tabItem {
                    Label("Vital Signs", systemImage: "heart.fill")
            }
            
            SettingsView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
