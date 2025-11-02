//
//  PredictionCard.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI

struct PredictionCard: View {
    var scenario: Scenario
    var xValue: Double
    var prediction: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForScenario)
                    .foregroundStyle(.secondary)
                Text(scenario.xLabel(xValue))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text(scenario.yLabel(prediction))
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LinearGradient(colors: [.orange.opacity(0.3), .pink.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        )
    }
    
    var iconForScenario: String {
        switch scenario {
        case .weather: return "thermometer.sun.fill"
        case .housing: return "house.fill"
        case .sales: return "chart.line.uptrend.xyaxis"
        }
    }
}
