//
//  ContentView.swift
//  HealthKitDrink
//
//  Created by Kyeongmo Yang on 6/23/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var waterIntake: Double = 0.0
    @State private var amountToAdd: String = ""
    @State private var isAuthorized: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isAuthorized {
                Text("Today's Water Intake: \(waterIntake, specifier: "%.2f") liters")
                    .padding()
                
                TextField("Enter amount in liters", text: $amountToAdd)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .padding()
                
                Button {
                    Task {
                        try await addWaterIntake()
                    }
                } label: {
                    Text("Add Water Intake")
                }
                .padding()
                
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            } else {
                Text("Requesting HealthKit Authorization...")
                    .padding()
            }
        }
        .onAppear {
            Task {
                try await healthKitManager.requestAuthorization()
                isAuthorized = true
                try await fetchWaterIntake()
            }
        }
    }
    
    private func addWaterIntake() async throws {
        guard let amount = Double(amountToAdd) else {
            errorMessage = "Invalid amount"
            return
        }
        
        try await healthKitManager.saveWaterIntake(amount: amount, date: Date())
        try await fetchWaterIntake()
        amountToAdd = ""
    }
    
    private func fetchWaterIntake() async throws {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        waterIntake = try await healthKitManager.readWaterIntake(startDate: startOfDay, endDate: Date())
    }
}


#Preview {
    ContentView()
}
