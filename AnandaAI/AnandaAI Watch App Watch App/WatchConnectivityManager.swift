////
////  WatchConnectivityManager.swift
////  AnandaAI
////
////  Created by Diya Maria on 09/11/24.
////
//
//import WatchConnectivity
//
//// Remove the 'private' access modifier
//class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
//    static let shared = WatchConnectivityManager()
//    
//    override init() {
//        super.init()
//    }
//    
//    var session: WCSession?
//    
//    func setupWatchConnectivity() {
//        if WCSession.isSupported() {
//            session = WCSession.default
//            session?.delegate = self
//            session?.activate()
//        }
//    }
//    
//    // MARK: - WCSessionDelegate Methods
//    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
//        if let error = error {
//            print("WCSession activation failed with error: \(error.localizedDescription)")
//        } else {
//            print("WCSession activated successfully with state: \(state.rawValue)")
//        }
//    }
//
//    func sessionReachabilityDidChange(_ session: WCSession) {
//        print("Reachability changed: \(session.isReachable)")
//    }
//
//    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
//        print("Message received: \(message)")
//    }
//    
//    func sendMessage(data: [String: Any]) {
//        guard let session = session, session.isReachable else {
//            print("iPhone is not reachable")
//            return
//        }
//
//        session.sendMessage(data, replyHandler: nil) { error in
//            print("Failed to send message: \(error.localizedDescription)")
//        }
//    }
//
//}

//import WatchKit
//import WatchConnectivity
//import UserNotifications
//
//class InterfaceController: WKInterfaceController, WCSessionDelegate {
//    
//    override func awake(withContext context: Any?) {
//        super.awake(withContext: context)
//        setupWCSession()
//        requestNotificationPermission()
//    }
//    
//    // Set up WatchConnectivity session
//    func setupWCSession() {
//        if WCSession.isSupported() {
//            let session = WCSession.default
//            session.delegate = self
//            session.activate()
//        }
//    }
//    
//    // Request notification permissions
//    func requestNotificationPermission() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//            if let error = error {
//                print("Error requesting notification permissions: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    // Receive message from iPhone
//    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
//        if let medicationName = message["medicationName"] as? String,
//           let medicationTime = message["medicationTime"] as? String {
//            scheduleNotification(medicationName: medicationName, medicationTime: medicationTime)
//        }
//    }
//    
//    // Schedule local notification
//    func scheduleNotification(medicationName: String, medicationTime: String) {
//        let content = UNMutableNotificationContent()
//        content.title = "Medication Reminder"
//        content.body = "It's time to take your medication: \(medicationName)"
//        content.sound = .default
//        
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//        
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("Error scheduling notification: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    // WatchConnectivity delegate method for activation state changes
//    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//        if let error = error {
//            print("WCSession activation error: \(error.localizedDescription)")
//        }
//    }
//}
//
