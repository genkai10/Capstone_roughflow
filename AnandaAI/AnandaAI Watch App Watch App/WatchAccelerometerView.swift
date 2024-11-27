//
//  WatchAccelerometerView.swift
//  AnandaAI
//
//  Created by Diya Maria on 09/11/24.
//

//
//  WatchAccelerometerView.swift
//  AnandaAI
//
//  Created by Diya Maria on 09/11/24.
//

import SwiftUI
import CoreMotion
import UserNotifications

struct WatchAccelerometerView: View {
    @State private var slidingWindow: [[Double]] = []
    @State private var latestAccelerometerData: [Double] = [0, 0, 0, 0, 0]
    @State private var fallDetected: Bool = false
    @State private var backendConnectionStatus: String = "Not connected"
    let windowSize = 50
    let motionManager = CMMotionManager()
    @State private var startTime: TimeInterval = 0

    var body: some View {
        VStack {
            Text("Watch Accelerometer")
                .font(.headline)
                .padding(.top, 10)
            ScrollView {
                VStack {
                    Text("Connection: \(String( backendConnectionStatus)) ")
                    Text("Time: \(Int(latestAccelerometerData[0])) ms")
                    Text("SV_total: \(String(format: "%.5f", latestAccelerometerData[1]))")
                    Text("Ax: \(String(format: "%.5f", latestAccelerometerData[2]))")
                    Text("Ay: \(String(format: "%.5f", latestAccelerometerData[3]))")
                    Text("Az: \(String(format: "%.5f", latestAccelerometerData[4]))")
                }
                .padding()
                
                Text(fallDetected ? "Fall Detected!" : "No Fall Detected")
                    .font(.title)
                    .foregroundColor(fallDetected ? .red : .green)
                    .padding()
                
                Button("Start Monitoring") {
                    startAccelerometerUpdates()
                }
                .padding(.top, 10)
                .font(.body) // Adjusted font size for better fitting
                .frame(maxWidth: .infinity, minHeight: 50) // Ensure button is large enough to tap
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 10)
            }
            .padding()
        }
        .onAppear {
            requestNotificationPermission()
        }
    }

    func startAccelerometerUpdates() {
        sendFallNotification()
        if motionManager.isAccelerometerAvailable {
            startTime = Date().timeIntervalSince1970 * 1000
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                guard let data = data else { return }

                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                let vectorSum = sqrt(x * x + y * y + z * z)

                // Capture the current time in milliseconds
                let currentTime = Int(Date().timeIntervalSince1970 * 1000 - startTime)

                // Update the latest accelerometer data
                latestAccelerometerData = [Double(currentTime), vectorSum, x, y, z]

                // Add data to sliding window
                addDataToWindow([Double(currentTime), vectorSum, x, y, z])
            }
        }
    }

    func addDataToWindow(_ data: [Double]) {
        slidingWindow.append(data)

        if slidingWindow.count == windowSize {
            // Send data directly to the backend once the window is full
            sendDataToBackend()
            slidingWindow.removeAll()
        }
    }

    func sendDataToBackend() {
        //        guard let url = URL(string: "http://192.168.1.18:5000/predict") else {
        //            print("Invalid URL")
        //            return
        //        }
        //
        //        var request = URLRequest(url: url)
        //        request.httpMethod = "POST"
        //        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //
        //        // Create JSON body
        //        let body: [String: Any] = [
        //            "accelerometer_data": slidingWindow
        //        ]
        //
        //        do {
        //            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
        //            request.httpBody = jsonData
        //
        //            let task = URLSession.shared.dataTask(with: request) { data, response, error in
        //                if let error = error {
        //                    print("Error sending data to backend: \(error.localizedDescription)")
        //                    return
        //                }
        //                print("Successfully sent data to backend")
        //            }
        //
        //            task.resume()
        //
        //        } catch {
        //            print("Error creating JSON: \(error.localizedDescription)")
        //        }
        //    }
        
        let backendURL = "http://192.168.1.68:5000/predict"
        guard let url = URL(string: backendURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create JSON body with accelerometer data
        let jsonBody: [String: Any] = ["accelerometer_data": slidingWindow]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody, options: []) else {
            print("Failed to serialize JSON")
            return
        }
        
        request.httpBody = jsonData
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    backendConnectionStatus = "Connected"
                }
            } else {
                DispatchQueue.main.async {
                    backendConnectionStatus = "Connection Failed"
                }
            }
            
            // Parse the prediction response
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let predictions = jsonResponse["predictions"] as? [String] {
                DispatchQueue.main.async {
                    let currentFallDetected = predictions.contains("Fall Detected")
                    if currentFallDetected && !fallDetected { // Check if a fall is detected and it was not already detected
                        fallDetected = true
                        sendFallNotification()
                        //                        sendFallNotification() // Send notification immediately
                    } else if !currentFallDetected {
                        fallDetected = false // Reset fall detection state
                    }
                }
            }
        }
        task.resume()
    }
    
    func requestNotificationPermission() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if granted {
                    print("Notification permission granted")
                } else {
                    print("Notification permission denied")
                }
            }
        }
    
    func sendFallNotification() {
            let content = UNMutableNotificationContent()
            content.title = "Fall Detected!"
            content.body = "A fall has been detected. Please check immediately."
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Notification scheduled")
                }
            }
        }
}

struct WatchAccelerometerView_Previews: PreviewProvider {
    static var previews: some View {
        WatchAccelerometerView()
    }
}
