//
//  PhaseIndicator.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI

struct PhaseIndicator: View {
    var phase: TrainingPhase
    var currentEpoch: Int
    var totalEpochs: Int
    var gradientMagnitude: Double
    var isStepMode: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Phase icon and label
            HStack(spacing: 6) {
                Group {
                    switch phase {
                    case .idle:
                        Image(systemName: "pause.circle.fill")
                            .foregroundStyle(.gray)
                    case .training:
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.orange)
                            .symbolEffect(.rotate, options: .repeat(.continuous))
                    case .makingPrediction:
                        Image(systemName: "arrow.forward.circle.fill")
                            .foregroundStyle(.blue)
                            .symbolEffect(.pulse, options: .repeat(.continuous))
                    case .calculatingError:
                        Image(systemName: "ruler.fill")
                            .foregroundStyle(.red)
                            .symbolEffect(.pulse, options: .repeat(.continuous))
                    case .learningFromError:
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(.green)
                            .symbolEffect(.pulse, options: .repeat(.continuous))
                    case .testing, .adjusting:
                        // Not used anymore
                        EmptyView()
                    }
                }
                .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(phaseText)
                        .font(.headline)
                        .foregroundStyle(phaseColor)
                    
                    Text(phaseDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if phase != .idle {
                        Text("Epoche \(currentEpoch)/\(totalEpochs)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Gradient magnitude indicator (when learning)
            if phase == .training || phase == .learningFromError {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Gradient")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(gradientMagnitude, format: .number.precision(.fractionLength(4)))
                        .font(.caption)
                        .monospaced()
                        .foregroundStyle(phaseColor)
                }
            }
        }
        .padding(12)
        .background(phaseColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(phaseColor.opacity(0.3), lineWidth: 2)
        )
    }
    
    var phaseText: String {
        switch phase {
        case .idle:
            return "Bereit"
        case .training:
            return "Training läuft..."
        case .makingPrediction:
            return "1. Vorhersage"
        case .calculatingError:
            return "2. Abweichung berechnen"
        case .learningFromError:
            return "3. Daraus lernen"
        case .testing, .adjusting:
            return ""
        }
    }
    
    var phaseDescription: String {
        switch phase {
        case .idle:
            return "Warte auf Start"
        case .training:
            return "Automatisches Training"
        case .makingPrediction:
            return "Modell macht Vorhersagen"
        case .calculatingError:
            return "Abweichungen zu echten Werten"
        case .learningFromError:
            return "Parameter werden angepasst"
        case .testing, .adjusting:
            return ""
        }
    }
    
    var phaseColor: Color {
        switch phase {
        case .idle:
            return .gray
        case .training:
            return .orange
        case .makingPrediction:
            return .blue
        case .calculatingError:
            return .red
        case .learningFromError:
            return .green
        case .testing, .adjusting:
            return .gray
        }
    }
}
