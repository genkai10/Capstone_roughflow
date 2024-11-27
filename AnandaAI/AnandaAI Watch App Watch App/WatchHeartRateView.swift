//
//  WatchHeartRateView.swift
//  AnandaAI
//
//  Created by Diya Maria on 09/11/24.
//

import SwiftUI
import HealthKit

struct WatchHeartRateView: View {
    @State private var heartRate: Double? = nil
    @State private var latestBloodOxygen: Double = 0.0
    @State private var respiratoryRate: Double? = nil
    @State private var isMonitoring = false
    private let healthStore = HKHealthStore()
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!

//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                Text("Heart Rate Monitor")
//                    .font(.headline)
//                    .padding()
//
//                // Display the heart rate
//                if let heartRate = heartRate {
//                    Text("Current Heart Rate")
//                        .font(.subheadline)
//                    Text("\(Int(heartRate)) BPM")
//                        .font(.system(size: 40))
//                        .fontWeight(.bold)
//                        .foregroundColor(.red)
//                } else {
//                    Text("Heart rate data not available")
//                        .font(.subheadline)
//                }
//
//                // Button to start or stop monitoring
//                Button(isMonitoring ? "Stop Monitoring" : "Start Monitoring") {
//                    isMonitoring ? stopHeartRateMonitoring() : startHeartRateMonitoring()
//                }
//                .padding()
//                .background(isMonitoring ? Color.red : Color.green)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//            }
//            .padding()
//        }
//        .onAppear {
//            requestHealthAuthorization()
//        }
//    }
//    
    var body: some View {
            ScrollView {
                VStack {
                    Text("Heart Rate")
                        .font(.title)
                        .padding()

                    if let heartRate = heartRate {
                        Text("Current Heart Rate")
                            .font(.subheadline)
                        Text("\(Int(heartRate)) BPM")
                            .font(.system(size: 40))
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    } else {
                        Text("Heart rate data not available")
                            .font(.subheadline)
                    }

                    Text("SpO2 Level")
                        .font(.title)
                        .padding()
                    
                    Text("\(String(format: "%.1f", latestBloodOxygen))%")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .padding()

                    Text("Respiratory Rate")
                        .font(.title)
                        .padding()
                    
                    if let respiratoryRate = respiratoryRate {
                        Text("\(String(format: "%.1f", respiratoryRate)) breaths/min")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                            .padding()
                    } else {
                        Text("Respiratory rate data not available")
                            .font(.subheadline)
                    }

                    Button("Start Monitoring") {
                        startHeartRateMonitoring()
                        startBloodOxygenQuery()
                        startRespiratoryRateQuery()
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            .onAppear {
                requestHealthAuthorization()
            }
        }


//    func requestHealthAuthorization() {
//        let typesToRead: Set = [heartRateType]
//        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
//            if !success {
//                print("Health data authorization failed")
//            }
//        }
//    }
    
    
    // below code given for both HR and spo2
    func requestHealthAuthorization() {
        let healthStore = HKHealthStore()
        
        // Define the data types you want to read
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let bloodOxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        let respiratoryRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!

        let typesToRead: Set<HKObjectType> = [heartRateType, bloodOxygenType, respiratoryRateType]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            if success {
                print("Authorization granted for heart rate, SpO2, and respiratory rate")
            } else if let error = error {
                print("Authorization error: \(error.localizedDescription)")
            }
        }
    }


    func startBloodOxygenQuery() {
        let bloodOxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        let query = HKAnchoredObjectQuery(type: bloodOxygenType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, _, _, _ in
            guard let samples = samples as? [HKQuantitySample] else { return }
            
            // Get the most recent SpO2 value
            if let latestSample = samples.last {
                let bloodOxygenLevel = latestSample.quantity.doubleValue(for: .percent()) * 100
                DispatchQueue.main.async {
                    self.latestBloodOxygen = bloodOxygenLevel
                    print("SpO2 Level: \(bloodOxygenLevel)%")
                }
            }
        }
        healthStore.execute(query)
    }
    
 
    
    
    func startHeartRateMonitoring() {
        isMonitoring = true
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { _, _, error in
            if error == nil {
                fetchLatestHeartRate()
            }
        }
        healthStore.execute(query)
    }

    func stopHeartRateMonitoring() {
        isMonitoring = false
    }

    func fetchLatestHeartRate() {
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let heartRateValue = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async {
                self.heartRate = heartRateValue
            }
        }
        healthStore.execute(query)
    }
    
    func startRespiratoryRateQuery() {
        let query = HKSampleQuery(sampleType: respiratoryRateType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    self.respiratoryRate = nil
                }
                print("No respiratory rate data available")
                return
            }
            
            // Log the available samples to check if any data exists
            print("Found \(samples.count) respiratory rate samples.")
            
            if let sample = samples.first {
                let respiratoryRateValue = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                DispatchQueue.main.async {
                    self.respiratoryRate = respiratoryRateValue
                }
            } else {
                DispatchQueue.main.async {
                    self.respiratoryRate = nil
                }
                print("No respiratory rate data in the sample.")
            }
        }
        healthStore.execute(query)
    }

}

struct WatchHeartRateView_Previews: PreviewProvider {
    static var previews: some View {
        WatchHeartRateView()
    }
}
