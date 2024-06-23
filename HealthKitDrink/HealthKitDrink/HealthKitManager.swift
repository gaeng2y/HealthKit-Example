//
//  HealthKitManager.swift
//  HealthKitDrink
//
//  Created by Kyeongmo Yang on 6/24/24.
//

import Foundation
import HealthKit

enum HealthKitError: Error {
    case failedQuantityType
    case failedFetchResult
}

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    func requestAuthorization() async throws {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthKitError.failedQuantityType
        }
        
        try await healthStore.requestAuthorization(toShare: [waterType], read: [waterType])
    }
    
    func saveWaterIntake(amount: Double, date: Date) async throws {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthKitError.failedQuantityType
        }
        
        let waterQuantity = HKQuantity(unit: .liter(), doubleValue: amount)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: date, end: date)
        
        try await healthStore.save(waterSample)
    }
    
    func readWaterIntake(startDate: Date, endDate: Date) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
                continuation.resume(throwing: HealthKitError.failedQuantityType)
                return
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { query, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(throwing: HealthKitError.failedFetchResult)
                    return
                }
                
                let totalWater = sum.doubleValue(for: .liter())
                continuation.resume(returning: totalWater)
            }
            
            healthStore.execute(query)
        }
    }
}
