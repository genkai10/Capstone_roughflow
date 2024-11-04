import SwiftUI
import SocketIO

struct VideoView: View {
    @State private var predictionText: String = "Waiting for prediction..."
    private var socketManager: SocketManager
    private var socket: SocketIOClient
    
    init() {
        // Set up the socket manager and socket client
        socketManager = SocketManager(socketURL: URL(string: "http://localhost:5000")!, config: [.log(true), .compress])
        socket = socketManager.defaultSocket
        
        // Connect to the server
        socket.connect()
        
        // Add event handlers
        addSocketHandlers()
    }
    
    var body: some View {
        VStack {
            Text(predictionText)
                .font(.title)
                .padding()
            
            Spacer()
            
            Text("Video Feed Placeholder")
                .frame(width: 300, height: 400)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2)
                )
            
            Spacer()
        }
        .onAppear {
            // Ensure the socket is connected when the view appears
            socket.connect()
        }
        .onDisappear {
            // Disconnect the socket when the view disappears
            socket.disconnect()
        }
    }
    
    private func addSocketHandlers() {
        // Set up the event handler for receiving new predictions
        socket.on("new_prediction") { data, ack in
            if let predictionData = data[0] as? [String: Any],
               let action = predictionData["action"] as? String {
                DispatchQueue.main.async {
                    self.predictionText = "Prediction: \(action)"
                }
            }
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
