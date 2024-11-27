import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import WatchConnectivity

struct ProfileView: View {
    @State private var medications: [Medication] = []
    @State private var newMedicationName = ""
    @State private var newMedicationTime = Date()
    
    var body: some View {
        VStack {
            Text("Your Medications")
                .font(.title)
            
            List {
                ForEach(medications, id: \.id) { med in
                    VStack(alignment: .leading) {
                        Text("Name: \(med.name)")
                        Text("Time: \(med.time.formatted(.dateTime.hour().minute()))")
                        
                        Button(action: {
                            deleteMedication(med)
                        }) {
                            Text("Delete")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            VStack {
                TextField("Medication Name", text: $newMedicationName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                DatePicker("Time", selection: $newMedicationTime, displayedComponents: .hourAndMinute)
                    .padding()

                Button("Add Medication") {
                    addMedication()
                }
                .padding()
            }
            .padding()
        }
        .onAppear {
            loadMedications()
            requestNotificationPermission()
            //activateWCSession()
        }
    }
    
    // Request notification permissions
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func loadMedications() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                if let meds = document.data()?["medications"] as? [[String: Any]] {
                    self.medications = meds.map { data in
                        let name = data["name"] as? String ?? ""
                        let timestamp = data["time"] as? Timestamp ?? Timestamp()
                        let med = Medication(name: name, time: timestamp.dateValue())
                        scheduleNotification(for: med)
                        return med
                    }
                }
            } else {
                print("Error loading medications: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func addMedication() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let newMed = Medication(name: newMedicationName, time: newMedicationTime)
        medications.append(newMed)
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).updateData([
            "medications": FieldValue.arrayUnion([
                ["name": newMed.name, "time": Timestamp(date: newMed.time)]
            ])
        ]) { error in
            if let error = error {
                print("Error updating medications: \(error.localizedDescription)")
            }
        }
        
        // Schedule notification for the newly added medication
        scheduleNotification(for: newMed)
    }
    
    func deleteMedication(_ medication: Medication) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        medications.removeAll { $0.id == medication.id }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).updateData([
            "medications": FieldValue.arrayRemove([
                ["name": medication.name, "time": Timestamp(date: medication.time)]
            ])
        ]) { error in
            if let error = error {
                print("Error deleting medication: \(error.localizedDescription)")
            }
        }
        
        // Cancel scheduled notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [medication.id.uuidString])
    }
    
    // Function to schedule a local notification
//    func scheduleNotification(for medication: Medication) {
//        let content = UNMutableNotificationContent()
//        content.title = "Medication Reminder"
//        content.body = "It's time to take your medication: \(medication.name)"
//        content.sound = .default
//
//        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: medication.time)
//        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
//        
//        let request = UNNotificationRequest(identifier: medication.id.uuidString, content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("Error scheduling notification: \(error.localizedDescription)")
//            }
//        }
//    }
    
    func scheduleNotification(for medication: Medication) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "It's time to take your medication: \(medication.name)"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: medication.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: medication.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }

        // Send medication data to the Watch
        let medicationData: [String: Any] = [
            "medicationName": medication.name,
            "medicationTime": medication.time.formatted(.dateTime.hour().minute())
        ]
        sendMedicationToWatch(data: medicationData)
    }

    func sendMedicationToWatch(data: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }

        WCSession.default.sendMessage(data, replyHandler: nil) { error in
            print("Error sending message to Watch: \(error.localizedDescription)")
        }
    }
    
//    func activateWCSession() {
//            if WCSession.isSupported() {
//                let session = WCSession.default
//                session.delegate = WatchConnectivityManager.shared
//                session.activate()
//            }
//        }

}

struct Medication: Identifiable {
    var id = UUID()
    var name: String
    var time: Date
}
