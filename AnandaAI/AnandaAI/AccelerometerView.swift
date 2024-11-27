import SwiftUI
import CoreMotion
import UserNotifications


struct AccelerometerView: View {
    @State private var slidingWindow: [[Double]] = []
    @State private var backendConnectionStatus: String = "Not Connected"
    @State private var latestAccelerometerData: [Double] = [0, 0, 0, 0, 0]
    @State private var fallDetected: Bool = false
    let windowSize = 30 // Capture 50 samples for 5 seconds (assuming 0.1s interval)
    let motionManager = CMMotionManager()
    let backendURL = "http://192.168.1.68:5000/predict" // Update this to your backend URL if needed
    let fileManager = FileManager.default
    @State private var startTime: TimeInterval = 0 // To track the timestamp

    var body: some View {
        VStack {
            Text("Accelerometer Data")
                .font(.title)

            Text("Backend Status: \(backendConnectionStatus)")
                .foregroundColor(backendConnectionStatus == "Connected" ? .green : .red)
                .padding()

            // Display the latest accelerometer data
            VStack {
                Text("Time: \(Int(latestAccelerometerData[0])) ms")
                Text("SV_total: \(String(format: "%.5f", latestAccelerometerData[1]))")
                Text("Ax: \(String(format: "%.5f", latestAccelerometerData[2]))")
                Text("Ay: \(String(format: "%.5f", latestAccelerometerData[3]))")
                Text("Az: \(String(format: "%.5f", latestAccelerometerData[4]))")
            }
            .padding()
            
            // Display fall detection status
            Text(fallDetected ? "Fall Detected!" : "No Fall Detected")
                .font(.title)
                .foregroundColor(fallDetected ? .red : .green)
                .padding()
            
            Button("Start Monitoring") {
                startAccelerometerUpdates()
            }
            .padding()
        }
        .onAppear {
            requestNotificationPermission()

        }
    }

//    func requestNotificationPermission() {
//        let center = UNUserNotificationCenter.current()
//        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//            if let error = error {
//                print("Notification authorization error: \(error.localizedDescription)")
//            }
//        }
//    }
    
    func requestNotificationPermission() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if granted {
                    print("Notification Permission Granted")
                } else if let error = error {
                    print("Notification permission denied because: \(error.localizedDescription).")
                }
            }
        }

    func startAccelerometerUpdates() {
        if motionManager.isAccelerometerAvailable {
            startTime = Date().timeIntervalSince1970 * 1000 // Start time in milliseconds
            motionManager.accelerometerUpdateInterval = 0.1  // 10 Hz or adjust as needed
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                guard let data = data else { return }
                
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                let vectorSum = sqrt(x * x + y * y + z * z)

                // Capture the time in milliseconds since the start
                let currentTime = Int(Date().timeIntervalSince1970 * 1000 - startTime)

                // Update the latest accelerometer data
                latestAccelerometerData = [Double(currentTime), vectorSum, x, y, z]

                // Add accelerometer data to the sliding window
                addDataToWindow([Double(currentTime), vectorSum, x, y, z])
            }
        }
    }

    func addDataToWindow(_ data: [Double]) {
        slidingWindow.append(data)
        
        if slidingWindow.count == windowSize {
            // 3 seconds of data captured, create CSV and send to backend
            createCSV(from: slidingWindow)
            sendAccelerometerDataToBackend()
            // Clear the window for the next batch of data
            slidingWindow.removeAll()
        }
    }

    func createCSV(from dataArray: [[Double]]) {
        var csvString = "time,SV_total,Ax,Ay,Az\n"
        
        for data in dataArray {
            let row = "\(Int(data[0])),\(data[1]),\(data[2]),\(data[3]),\(data[4])\n"
            csvString.append(row)
        }

        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = documentDirectory.appendingPathComponent("accelerometer_data.csv")
            do {
                try csvString.write(to: filePath, atomically: true, encoding: .utf8)
                print("CSV created successfully at: \(filePath)")
            } catch {
                print("Failed to create CSV: \(error)")
            }
        }
    }

//    func sendAccelerometerDataToBackend() {
//        guard let url = URL(string: backendURL) else { return }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        // Create JSON body with accelerometer data
//        let jsonBody: [String: Any] = ["accelerometer_data": slidingWindow]
//        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody, options: []) else {
//            print("Failed to serialize JSON")
//            return
//        }
//        
//        request.httpBody = jsonData
//        
//        // Send the request
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            guard let data = data, error == nil else {
//                print("Error: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
//                DispatchQueue.main.async {
//                    backendConnectionStatus = "Connected"
//                }
//            } else {
//                DispatchQueue.main.async {
//                    backendConnectionStatus = "Connection Failed"
//                }
//            }
//            
//            // Parse the prediction response
//            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//               let predictions = jsonResponse["predictions"] as? [String] {
//                DispatchQueue.main.async {
//                    fallDetected = predictions.contains("Fall Detected")
//                }
//                if fallDetected {
//                    sendFallNotification()
//                }
//            }
//        }
//        task.resume()
//    }
    
    func sendAccelerometerDataToBackend() {
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
                        sendFallNotification() // Send notification immediately
                    } else if !currentFallDetected {
                        fallDetected = false // Reset fall detection state
                    }
                }
            }
        }
        task.resume()
    }


    func sendFallNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Fall Detected"
        content.body = "A fall has been detected. Please check."
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error in sending notification: \(error.localizedDescription)")
            } else {
                print("Notification sent successfully.")
            }
        }
    }
}

struct AccelerometerView_Previews: PreviewProvider {
    static var previews: some View {
        AccelerometerView()
    }
}
