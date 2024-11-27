//
//  HeartRateManager.swift
//  AnandaAI
//
//  Created by Diya Maria on 09/11/24.
//

import Foundation
import HealthKit

class HeartRateManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    
    @Published var heartRate: Double?

    // Request authorization to access heart rate data
    func requestAuthorization() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToShare: Set<HKSampleType> = [] // No data to write to HealthKit
        let typesToRead: Set<HKObjectType> = [heartRateType] // Only reading heart rate data
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                print("HealthKit authorization granted.")
            } else if let error = error {
                print("Authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    // Start monitoring heart rate
    func startHeartRateMonitoring() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }
        
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    // Process heart rate samples
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        guard let sample = samples.last else { return }
        
        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let heartRateValue = sample.quantity.doubleValue(for: heartRateUnit)
        
        DispatchQueue.main.async {
            self.heartRate = heartRateValue
        }
    }
}
