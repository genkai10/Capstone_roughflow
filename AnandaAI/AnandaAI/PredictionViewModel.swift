//
//  PredictionViewModel.swift
//  AnandaAI
//
//  Created by Diya Maria on 04/11/24.
//

//import SwiftUI
//import SocketIO
//import Combine
//
//class PredictionViewModel: ObservableObject {
//    @Published var predictionText: String = "Waiting for prediction..."
//    private var socketManager: SocketManager?
//    private var socket: SocketIOClient?
//    
//    func startPrediction() {
//        // Initialize socket manager and socket client only when called
//        socketManager = SocketManager(socketURL: URL(string: "http://192.168.1.68:5000")!, config: [.log(true), .compress])
//        socket = socketManager?.defaultSocket
//        
//        addSocketHandlers()
//        socket?.connect()
//    }
//    
//    private func addSocketHandlers() {
//        // Confirm connection and emit start_prediction
//        socket?.on(clientEvent: .connect) { [weak self] data, ack in
//            print("Socket connected!")
//            self?.socket?.emit("start_prediction")
//        }
//        
//        // Listen for `new_prediction` events
//        socket?.on("new_prediction") { [weak self] data, ack in
//            if let predictionData = data[0] as? [String: Any],
//               let action = predictionData["action"] as? String {
//                print("Received action: \(action)")
//                DispatchQueue.main.async {
//                    self?.predictionText = "Prediction: \(action)"
//                }
//            } else {
//                print("Data format mismatch or missing 'action' key")
//            }
//        }
//    }
//    
//    deinit {
//        socket?.disconnect()
//    }
//}


//import SwiftUI
//import SocketIO
//import Combine
//
//class PredictionViewModel: ObservableObject {
//    @Published var predictionText: String = "Waiting for prediction..."
//    private var socketManager: SocketManager?
//    private var socket: SocketIOClient?
//    
//    func startPrediction() {
//        // Initialize socket manager and socket client only when called
//        socketManager = SocketManager(socketURL: URL(string: "http://192.168.1.68:5000")!, config: [.log(true), .compress])
//        socket = socketManager?.defaultSocket
//        
//        addSocketHandlers()
//        socket?.connect()
//        
//        // Optionally, emit a start prediction event to begin processing
//        socket?.emit("start_prediction")
//    }
//    
//    private func addSocketHandlers() {
//        // Confirm connection and emit start_prediction
//        socket?.on(clientEvent: .connect) { [weak self] data, ack in
//            print("Socket connected!")
//            // Optionally start prediction when socket connects
//            self?.socket?.emit("start_prediction")
//        }
//        
//        // Listen for `new_prediction` events
//        socket?.on("new_prediction") { [weak self] data, ack in
//            if let predictionData = data[0] as? [String: Any],
//               let action = predictionData["action"] as? String {
//                print("Received action: \(action)")
//                DispatchQueue.main.async {
//                    self?.predictionText = "Prediction: \(action)" // Update UI with prediction
//                }
//            } else {
//                print("Data format mismatch or missing 'action' key")
//            }
//        }
//    }
//    
//    deinit {
//        socket?.disconnect()
//    }
//}

import SwiftUI
import SocketIO

class PredictionViewModel: ObservableObject {
    @Published var predictionText: String = "Waiting for Prediction..."
    @Published var videoFrame: UIImage? = nil // To hold the current video frame
    
    private var socketManager: SocketManager
    private var socket: SocketIOClient
    
    init() {
        // Initialize Socket.IO manager with the backend URL
        self.socketManager = SocketManager(socketURL: URL(string: "http://192.168.1.68:5000")!, config: [.log(true), .compress])
        self.socket = socketManager.defaultSocket
        
        setupSocketHandlers()
    }
    
    func startPrediction() {
        socket.connect() // Connect to the backend WebSocket server
        socket.emit("start_prediction") // Optionally, emit start_prediction
    }
    
    private func setupSocketHandlers() {
        // Handle connection
        socket.on(clientEvent: .connect) { _, _ in
            DispatchQueue.main.async {
                self.predictionText = "Connected to Backend"
            }
        }
        
        // Handle disconnection
        socket.on(clientEvent: .disconnect) { _, _ in
            DispatchQueue.main.async {
                self.predictionText = "Disconnected"
            }
        }
        
        // Handle prediction data
        socket.on("new_prediction") { [weak self] data, _ in
            if let predictionData = data[0] as? [String: Any],
               let action = predictionData["action"] as? String {
                DispatchQueue.main.async {
                    self?.predictionText = "Prediction: \(action)"
                }
            }
        }
        
        // Handle video frame data
//        socket.on("video_frame") { [weak self] data, _ in
//            guard let frameData = data.first as? String,
//                  let decodedData = Data(base64Encoded: frameData),
//                  let image = UIImage(data: decodedData) else { return }
//            
//            DispatchQueue.main.async {
//                self?.videoFrame = image
//            }
//        }
        socket.on("video_frame") { [weak self] data, _ in
            guard let frameData = data.first as? String else {
                print("Invalid data format for video_frame")
                return
            }
                
            // Decode base64 string into Data
            if let decodedData = Data(base64Encoded: frameData) {
                // Convert Data into UIImage
                if let image = UIImage(data: decodedData) {
                    DispatchQueue.main.async {
                        self?.videoFrame = image
                    }
                } else {
                    print("Failed to create UIImage from decoded data")
                }
            } else {
                print("Failed to decode base64 string")
            }
        }
    }
    
    deinit {
        socket.disconnect()
    }
}
