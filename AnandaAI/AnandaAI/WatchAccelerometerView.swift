////
////  WatchAccelerometerView.swift
////  AnandaAI
////
////  Created by Diya Maria on 05/11/24.
////
//
//import SwiftUI
//import CoreMotion
//import WatchConnectivity
//
//func sendDataToiPhone(_ data: [String: Any]) {
//    if WCSession.default.isReachable {
//        WCSession.default.sendMessage(data, replyHandler: nil) { error in
//            print("Error sending data: \(error.localizedDescription)")
//        }
//    }
//}
//struct WatchAccelerometerView: View {
//    @State private var accelerometerData: [Double] = [0, 0, 0, 0, 0] // Time, SV_total, Ax, Ay, Az
//    let motionManager = CMMotionManager()
//    let windowSize = 30
//    @State private var slidingWindow: [[Double]] = []
//
//    var body: some View {
//        VStack {
//            Text("Watch Accelerometer Data")
//                .font(.headline)
//
//            Text("SV_total: \(String(format: "%.5f", accelerometerData[1]))")
//            Text("Ax: \(String(format: "%.5f", accelerometerData[2]))")
//            Text("Ay: \(String(format: "%.5f", accelerometerData[3]))")
//            Text("Az: \(String(format: "%.5f", accelerometerData[4]))")
//                .padding()
//            
//            Button("Start Monitoring") {
//                startAccelerometerUpdates()
//            }
//        }
//        .onAppear {
//            if WCSession.isSupported() {
//                
//                WCSession.default.delegate = self
//                WCSession.default.activate()
//            }
//            startAccelerometerUpdates()
//        }
//    }
//
//    func startAccelerometerUpdates() {
//        if motionManager.isAccelerometerAvailable {
//            motionManager.accelerometerUpdateInterval = 0.1
//            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
//                guard let data = data else { return }
//
//                let x = data.acceleration.x
//                let y = data.acceleration.y
//                let z = data.acceleration.z
//                let vectorSum = sqrt(x * x + y * y + z * z)
//
//                // Track timestamp in milliseconds
//                let timestamp = Date().timeIntervalSince1970 * 1000
//                accelerometerData = [timestamp, vectorSum, x, y, z]
//                
//                // Update sliding window for batch processing
//                slidingWindow.append([timestamp, vectorSum, x, y, z])
//                if slidingWindow.count == windowSize {
//                    // Here you can process or send this data
//                    slidingWindow.removeAll()
//                }
//            }
//        }
//    }
//}
//
//struct WatchAccelerometerView_Previews: PreviewProvider {
//    static var previews: some View {
//        WatchAccelerometerView()
//    }
//}
