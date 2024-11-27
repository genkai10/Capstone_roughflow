//
//
//import SwiftUI
//import HealthKit
//import Charts
//
//struct VitalSignsView: View {
//    @State private var heartRateData: [Double] = []
//    @State private var oxygenSaturationData: [Double] = []
//    @State private var dates: [Date] = []
//    @State private var loading = true
//
//    let healthStore = HKHealthStore()
//
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    Text("Vital Signs Report (Last 24 Hours)")
//                        .font(.largeTitle)
//                        .bold()
//                        .padding(.top)
//                        .frame(maxWidth: .infinity, alignment: .center)
//
//                    if loading {
//                        ProgressView("Loading health data...")
//                            .progressViewStyle(CircularProgressViewStyle())
//                            .frame(maxWidth: .infinity, alignment: .center)
//                    } else {
//                        VStack(alignment: .leading, spacing: 20) {
//                            // Heart Rate Section
//                            VitalSignSection(
//                                title: "Heart Rate (BPM)",
//                                data: heartRateData,
//                                dates: dates,
//                                dataLabel: "Heart Rate",
//                                color: .red
//                            )
//
//                            // SpO2 Section
//                            VitalSignSection(
//                                title: "SpO₂ Levels (%)",
//                                data: oxygenSaturationData,
//                                dates: dates,
//                                dataLabel: "SpO₂",
//                                color: .blue
//                            )
//                        }
//                        .padding(.horizontal)
//                    }
//                }
//            }
//            .navigationBarTitle("Vital Signs", displayMode: .inline)
//            .onAppear(perform: loadHealthData)
//        }
//    }
//
//    func loadHealthData() {
//        requestHealthKitAuthorization { success in
//            if success {
//                fetchHeartRateData()
//                fetchOxygenSaturationData()
//            } else {
//                print("HealthKit authorization failed.")
//                loading = false
//            }
//        }
//    }
//
//    func requestHealthKitAuthorization(completion: @escaping (Bool) -> Void) {
//        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
//        let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
//
//        let readTypes: Set<HKObjectType> = [heartRateType, oxygenSaturationType]
//
//        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
//            if let error = error {
//                print("HealthKit authorization error: \(error.localizedDescription)")
//            }
//            completion(success)
//        }
//    }
//
//    func fetchHeartRateData() {
//        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
//        fetchHealthData(for: heartRateType) { samples in
//            self.heartRateData = samples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
//            self.dates = samples.map { $0.startDate }
//            self.loading = false
//        }
//    }
//
//    func fetchOxygenSaturationData() {
//        let oxygenSaturationType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
//        fetchHealthData(for: oxygenSaturationType) { samples in
//            self.oxygenSaturationData = samples.map { $0.quantity.doubleValue(for: HKUnit.percent()) * 100 }
//        }
//    }
//
//    func fetchHealthData(for type: HKQuantityType, completion: @escaping ([HKQuantitySample]) -> Void) {
//        let now = Date()
//        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
//
//        let query = HKSampleQuery(
//            sampleType: type,
//            predicate: predicate,
//            limit: HKObjectQueryNoLimit,
//            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
//        ) { _, samples, error in
//            if let error = error {
//                print("Error fetching health data: \(error.localizedDescription)")
//                completion([])
//                return
//            }
//
//            let quantitySamples = samples as? [HKQuantitySample] ?? []
//            DispatchQueue.main.async {
//                completion(quantitySamples)
//            }
//        }
//
//        healthStore.execute(query)
//    }
//}
//
//struct VitalSignSection: View {
//    let title: String
//    let data: [Double]
//    let dates: [Date]
//    let dataLabel: String
//    let color: Color
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(title)
//                .font(.headline)
//                .bold()
//                .padding(.bottom, 5)
//
//            if data.isEmpty {
//                Text("No data available.")
//                    .foregroundColor(.gray)
//                    .padding(.vertical)
//            } else {
//                Chart {
//                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
//                        LineMark(
//                            x: .value("Time", dates[index], unit: .hour),
//                            y: .value(dataLabel, value)
//                        )
//                        .interpolationMethod(.catmullRom)
//                        .foregroundStyle(color)
//                        .lineStyle(StrokeStyle(lineWidth: 2))
//                    }
//                }
//                .frame(height: 200)
//                .padding(.vertical)
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(color.opacity(0.1))
//                )
//            }
//        }
//    }
//}

import SwiftUI
import HealthKit
import Charts

struct VitalSignsView: View {
    @State private var heartRateData: [Double] = []
    @State private var oxygenSaturationData: [Double] = []
    @State private var respiratoryRateData: [Double] = []
    @State private var dates: [Date] = []
    @State private var loading = true

    let healthStore = HKHealthStore()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Vital Signs Report (Last 24 Hours)")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .center)

                    if loading {
                        ProgressView("Loading health data...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        VStack(alignment: .leading, spacing: 20) {
                            // Heart Rate Section
                            VitalSignSection(
                                title: "Heart Rate (BPM)",
                                data: heartRateData,
                                dates: dates,
                                dataLabel: "Heart Rate",
                                color: .red
                            )

                            // SpO2 Section
                            VitalSignSection(
                                title: "SpO₂ Levels (%)",
                                data: oxygenSaturationData,
                                dates: dates,
                                dataLabel: "SpO₂",
                                color: .blue
                            )

                            // Respiratory Rate Section
                            VitalSignSection(
                                title: "Respiratory Rate (Breaths/Min)",
                                data: respiratoryRateData,
                                dates: dates,
                                dataLabel: "Respiratory Rate",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitle("Vital Signs", displayMode: .inline)
            .onAppear(perform: loadHealthData)
        }
    }

    func loadHealthData() {
        requestHealthKitAuthorization { success in
            if success {
                fetchHeartRateData()
                fetchOxygenSaturationData()
                fetchRespiratoryRateData()
            } else {
                print("HealthKit authorization failed.")
                loading = false
            }
        }
    }

    func requestHealthKitAuthorization(completion: @escaping (Bool) -> Void) {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        let respiratoryRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!

        let readTypes: Set<HKObjectType> = [heartRateType, oxygenSaturationType, respiratoryRateType]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error.localizedDescription)")
            }
            completion(success)
        }
    }

    func fetchHeartRateData() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        fetchHealthData(for: heartRateType) { samples in
            self.heartRateData = samples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
            self.dates = samples.map { $0.startDate }
            self.loading = false
        }
    }

    func fetchOxygenSaturationData() {
        let oxygenSaturationType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
        fetchHealthData(for: oxygenSaturationType) { samples in
            self.oxygenSaturationData = samples.map { $0.quantity.doubleValue(for: HKUnit.percent()) * 100 }
        }
    }

    func fetchRespiratoryRateData() {
        let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        fetchHealthData(for: respiratoryRateType) { samples in
            self.respiratoryRateData = samples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
        }
    }

    func fetchHealthData(for type: HKQuantityType, completion: @escaping ([HKQuantitySample]) -> Void) {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching health data: \(error.localizedDescription)")
                completion([])
                return
            }

            let quantitySamples = samples as? [HKQuantitySample] ?? []
            DispatchQueue.main.async {
                completion(quantitySamples)
            }
        }

        healthStore.execute(query)
    }
}

struct VitalSignSection: View {
    let title: String
    let data: [Double]
    let dates: [Date]
    let dataLabel: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .bold()
                .padding(.bottom, 5)

            if data.isEmpty {
                Text("No data available.")
                    .foregroundColor(.gray)
                    .padding(.vertical)
            } else {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Time", dates[index], unit: .hour),
                            y: .value(dataLabel, value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .frame(height: 200)
                .padding(.vertical)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.1))
                )
            }
        }
    }
}
