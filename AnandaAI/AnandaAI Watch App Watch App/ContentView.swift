//
//  ContentView.swift
//  AnandaAI Watch App Watch App
//
//  Created by Diya Maria on 05/11/24.
//

import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    
    @Published var ax: Double = 0.0
    @Published var ay: Double = 0.0
    @Published var az: Double = 0.0

    init() {
        startAccelerometer()
    }

    // Function to start the accelerometer updates
    func startAccelerometer() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1 // Update every 0.1 seconds
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                guard let self = self, let data = data else { return }
                self.ax = data.acceleration.x
                self.ay = data.acceleration.y
                self.az = data.acceleration.z
            }
        }
    }
    
    func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates()
    }
}


struct ContentView: View {
    @StateObject private var motionManager = MotionManager()
    
    var body: some View {
        VStack {
            Text("Accelerometer Data")
                .font(.headline)
                .padding()

            Text("Ax: \(motionManager.ax, specifier: "%.2f")")
            Text("Ay: \(motionManager.ay, specifier: "%.2f")")
            Text("Az: \(motionManager.az, specifier: "%.2f")")
        }
        .padding()
        .onAppear {
            motionManager.startAccelerometer()
        }
        .onDisappear {
            motionManager.stopAccelerometer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

