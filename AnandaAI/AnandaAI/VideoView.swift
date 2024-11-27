////
////  VideoView.swift
////  AnandaAI
////
////  Created by Diya Maria on 01/11/24.
////
//
//// VideoView.swift
//import SwiftUI
//import AVKit
//
//struct VideoView: View {
//    @State private var isDetectingFalls = false
//    private let videoCapture = VideoCapture() // Placeholder for your video capture setup
//
//    var body: some View {
//        VStack {
//            Text("Real-Time Fall Detection")
//                .font(.title)
//                .padding()
//
//            VideoPlayer(player: videoCapture.player) // Assuming VideoCapture handles AVPlayer setup
//                .onAppear {
//                    videoCapture.startCapture() // Start the video capture when the view appears
//                    isDetectingFalls = true // Start fall detection
//                }
//                .onDisappear {
//                    videoCapture.stopCapture() // Stop capture when leaving the view
//                    isDetectingFalls = false // Stop fall detection
//                }
//                .frame(height: 300)
//
//            if isDetectingFalls {
//                Text("Detecting falls...").padding()
//            }
//        }
//        .padding()
//        .navigationBarTitle("Fall Detection", displayMode: .inline)
//    }
//}
//
//// Placeholder class for video capture logic
//class VideoCapture: ObservableObject {
//    var player: AVPlayer {
//        // Placeholder: Return your configured AVPlayer instance
//        return AVPlayer()
//    }
//
//    func startCapture() {
//        // Add your video capture setup here
//    }
//
//    func stopCapture() {
//        // Stop the video capture here
//    }
//}




// hemanth 1st code, only loading screen

//import SwiftUI
//
//struct VideoView: View {
//    @State private var predictions: [String] = []
//    @State private var isLoading = false
//    let backendURL = "http://192.168.1.18:5000/predict" // Specify your backend URL here
//
//    var body: some View {
//        VStack {
//            if isLoading {
//                ProgressView("Loading predictions...")
//            } else {
//                List(predictions, id: \.self) { prediction in
//                    Text(prediction)
//                }
//                .onAppear(perform: fetchPredictions)
//            }
//        }
//        .navigationTitle("Action Predictions")
//    }
//
//    private func fetchPredictions() {
//        isLoading = true
//        
//        guard let url = URL(string: backendURL) else {
//            print("Invalid URL")
//            isLoading = false
//            return
//        }
//        
//        let task = URLSession.shared.dataTask(with: url) { data, response, error in
//            // Handle errors
//            if let error = error {
//                print("Error fetching predictions: \(error.localizedDescription)")
//                DispatchQueue.main.async {
//                    isLoading = false
//                }
//                return
//            }
//            
//            // Handle the response
//            guard let data = data else {
//                print("No data received")
//                DispatchQueue.main.async {
//                    isLoading = false
//                }
//                return
//            }
//
//            do {
//                // Decode the JSON response into an array of strings
//                let decodedPredictions = try JSONDecoder().decode([String].self, from: data)
//                DispatchQueue.main.async {
//                    predictions = decodedPredictions
//                    isLoading = false
//                }
//            } catch {
//                print("Failed to decode JSON: \(error.localizedDescription)")
//                DispatchQueue.main.async {
//                    isLoading = false
//                }
//            }
//        }
//
//        task.resume()
//    }
//}
//
//struct VideoView_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoView()
//    }
//}





// hemanth 2nd code

import SwiftUI
import SocketIO
import Combine

struct VideoView: View {
    @StateObject private var viewModel = PredictionViewModel()

    var body: some View {
        VStack {
            Text(viewModel.predictionText)
                .font(.title)
                .padding()
            
            Spacer()
            
//            Text("Video Feed Placeholder")
//                .frame(width: 300, height: 400)
//                .background(Color.gray.opacity(0.3))
//                .cornerRadius(10)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(Color.black, lineWidth: 2)
//                )
//            
//            Spacer()
            
            CameraView()
                .frame(width: 300, height: 400) // Adjust the size as needed
                .background(Color.gray.opacity(0.3)) // A background color for the camera view
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2) // Border for the camera feed
                )
                
            Spacer()
            
            Button(action: {
                viewModel.startPrediction() // Start backend process on button press
            }) {
                Text("Start Prediction")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}

