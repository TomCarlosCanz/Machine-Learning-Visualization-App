//
//  SupervisedLearningModel.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI
import Combine

struct SamplePoint: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
}

enum Scenario: String, CaseIterable, Identifiable {
    case weather = "Wetter (Temperatur)"
    case housing = "Immobilienpreise"
    case sales = "Verkaufszahlen"
    
    var id: String { rawValue }
    
    var trueSlope: Double {
        switch self {
        case .weather: return 2.2
        case .housing: return 2.8
        case .sales: return 1.5
        }
    }
    
    var trueIntercept: Double {
        switch self {
        case .weather: return 0.6
        case .housing: return 0.3
        case .sales: return 1.0
        }
    }
    
    var noise: Double {
        switch self {
        case .weather: return 0.16
        case .housing: return 0.22
        case .sales: return 0.12
        }
    }
    
    var description: String {
        switch self {
        case .weather: return "Temperatur basierend auf Tageszeit"
        case .housing: return "Hauspreis basierend auf Größe"
        case .sales: return "Umsatz basierend auf Werbebudget"
        }
    }
    
    // Real-world value mapping
    func xLabel(_ value: Double) -> String {
        switch self {
        case .weather:
            let hour = Int(value * 24)
            return "\(hour):00 Uhr"
        case .housing:
            let sqm = Int(value * 200 + 50) // 50-250 m²
            return "\(sqm) m²"
        case .sales:
            let budget = Int(value * 10000) // 0-10000€
            return "\(budget)€"
        }
    }
    
    func yLabel(_ value: Double) -> String {
        switch self {
        case .weather:
            let temp = value * 10 // Scale to reasonable temp range
            return String(format: "%.1f°C", temp)
        case .housing:
            let price = value * 200000 // Scale to reasonable price range
            return String(format: "%.0f€", price)
        case .sales:
            let sales = value * 1000 // Scale to reasonable sales numbers
            return String(format: "%.0f Verkäufe", sales)
        }
    }
    
    var xAxisLabel: String {
        switch self {
        case .weather: return "Tageszeit"
        case .housing: return "Wohnfläche"
        case .sales: return "Werbebudget"
        }
    }
    
    var yAxisLabel: String {
        switch self {
        case .weather: return "Temperatur"
        case .housing: return "Preis"
        case .sales: return "Verkäufe"
        }
    }
}

import SwiftUI

enum TrainingPhase {
    case idle
    case training
    case testing
    case adjusting
    
    // New phases for step-by-step mode
    case makingPrediction      // 1. Make predictions with current model
    case calculatingError      // 2. Calculate deviation from actual results
    case learningFromError     // 3. Update parameters based on errors
}


/*
 WHAT THIS CODE DOES:
 - The model of the model (if that makes sense): data used by viewModel
 */
