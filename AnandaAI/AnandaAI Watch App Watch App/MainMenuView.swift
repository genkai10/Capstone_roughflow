//
//  MainMenuView.swift
//  AnandaAI
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        VStack {
            NavigationLink(destination: WatchAccelerometerView()) {
                Text("Accelerometer")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            NavigationLink(destination: WatchHeartRateView()) {
                Text("Heart Rate")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
