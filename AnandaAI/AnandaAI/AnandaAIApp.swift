import SwiftUI
import Firebase
import WatchConnectivity

@main
struct AnandaAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}


class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        // Request notification permission
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        
        //activateWCSession()
        
        return true
    }
    
    // Request permission for notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // Handle notifications when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification alert when the app is in the foreground
        completionHandler([.alert, .sound])
    }

    // Handle notifications when tapped
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification response (if needed)
        completionHandler()
    }
    // Activate WatchConnectivity session
//    private func activateWCSession() {
//        if WCSession.isSupported() {
//            let session = WCSession.default
//            session.delegate = self
//            session.activate()
//        }
//    }
//        
//    // WatchConnectivity delegate methods
//    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//        if let error = error {
//            print("WCSession activation error: \(error.localizedDescription)")
//        }
//    }
//        
//    func sessionDidBecomeInactive(_ session: WCSession) {}
//    
//    func sessionDidDeactivate(_ session: WCSession) {
//        WCSession.default.activate()
//    }

}
