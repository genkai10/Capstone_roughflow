import UIKit
import SocketIO

class ViewController: UIViewController {
    
    // Initialize the manager with your server URL
    let manager = SocketManager(socketURL: URL(string: "http://192.168.1.19:5000")!, config: [.log(true), .compress])
    var socket: SocketIOClient!
    
    // Label to display predictions
    @IBOutlet weak var predictionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the socket client
        socket = manager.defaultSocket
        
        // Define event handlers
        addSocketHandlers()
        
        // Connect to the server
        socket.connect()
    }
    
    func addSocketHandlers() {
        // Handler for when the connection is successful
        socket.on(clientEvent: .connect) {data, ack in
            print("Connected to server")
            self.socket.emit("start_prediction")
        }
        
        // Handler for receiving predictions
        socket.on("new_prediction") { (data, ack) in
            if let predictionData = data[0] as? [String: Any],
               let action = predictionData["action"] as? String {
                DispatchQueue.main.async {
                    self.predictionLabel.text = "Prediction: \(action)"
                }
            }
        }
        
        // Handler for disconnection
        socket.on(clientEvent: .disconnect) {data, ack in
            print("Disconnected from server")
        }
    }
}
