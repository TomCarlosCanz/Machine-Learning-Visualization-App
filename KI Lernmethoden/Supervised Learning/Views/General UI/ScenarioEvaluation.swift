//
//  ScenarioEvaluation.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI

struct ScenarioEvaluation: View {
    @ObservedObject var vm: RegressionVM
    
    var sampleXValues: [Double] {
        [0.25, 0.5, 0.75]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(.orange)
                Text("Modell-Vorhersagen")
                    .font(.headline)
                Spacer()
                Text(vm.selectedScenario.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }
            
            Text("Das trainierte Modell trifft folgende Vorhersagen für \(vm.selectedScenario.xAxisLabel)-Werte:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(sampleXValues, id: \.self) { x in
                    let prediction = vm.slope * x + vm.intercept
                    PredictionCard(scenario: vm.selectedScenario, xValue: x, prediction: prediction)
                }
            }
            
            // Model quality indicator with MSE
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: qualityIcon)
                        .foregroundStyle(qualityColor)
                    Text(qualityText)
                        .font(.subheadline)
                        .foregroundStyle(qualityColor)
                    Spacer()
                }
                
                HStack {
                    Text("MSE (Mean Squared Error):")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(vm.trainLoss, format: .number.precision(.fractionLength(4)))
                        .font(.callout)
                        .bold()
                        .monospaced()
                        .foregroundStyle(.orange)
                }
                
                Text("Je niedriger der MSE-Wert, desto besser passt das Modell zu den Daten.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(qualityColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    var qualityText: String {
        let mse = vm.trainLoss
        if mse < 0.01 { return "Ausgezeichnete Anpassung" }
        else if mse < 0.05 { return "Gute Anpassung" }
        else if mse < 0.1 { return "Akzeptable Anpassung" }
        else { return "Verbesserungsbedarf" }
    }
    
    var qualityIcon: String {
        let mse = vm.trainLoss
        if mse < 0.01 { return "star.fill" }
        else if mse < 0.05 { return "checkmark.circle.fill" }
        else if mse < 0.1 { return "exclamationmark.circle.fill" }
        else { return "xmark.circle.fill" }
    }
    
    var qualityColor: Color {
        let mse = vm.trainLoss
        if mse < 0.01 { return .green }
        else if mse < 0.05 { return .green }
        else if mse < 0.1 { return .orange }
        else { return .red }
    }
}
