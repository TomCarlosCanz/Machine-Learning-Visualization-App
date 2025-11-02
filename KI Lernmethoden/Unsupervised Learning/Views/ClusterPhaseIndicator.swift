//
//  ClusterPhaseIndicator.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 05.01.26.
//
import SwiftUI

struct ClusterPhaseIndicator: View {
    var phase: ClusteringPhase
    var currentIteration: Int
    var maxIterations: Int
    var hasConverged: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Phase icon and label
            HStack(spacing: 6) {
                Group {
                    switch phase {
                    case .idle:
                        Image(systemName: hasConverged ? "checkmark.circle.fill" : "pause.circle.fill")
                            .foregroundStyle(hasConverged ? .green : .gray)
                    case .assignment:
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.blue)
                            .symbolEffect(.pulse)
                    case .update:
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.orange)
                            .symbolEffect(.rotate, options: .repeat(.continuous))
                    }
                }
                .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(phaseText)
                        .font(.headline)
                        .foregroundStyle(phaseColor)
                    
                    if phase == .assignment {
                        Text("Jeder Punkt wählt den nächsten Zentroid")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if phase == .update {
                        Text("Zentroide bewegen sich zum Clustermittelpunkt")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if phase != .idle {
                        Text("Iteration \(currentIteration)/\(maxIterations)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if hasConverged {
                        Text("Cluster sind stabil - keine Änderungen mehr")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            // Progress indicator
            if phase != .idle || hasConverged {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Fortschritt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(Double(currentIteration) / Double(maxIterations) * 100))%")
                        .font(.caption)
                        .bold()
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
            return hasConverged ? "Fertig - Konvergiert" : "Bereit zum Start"
        case .assignment:
            return "Schritt 1: Punkte zuweisen"
        case .update:
            return "Schritt 2: Zentroide verschieben"
        }
    }
    
    var phaseColor: Color {
        switch phase {
        case .idle:
            return hasConverged ? .green : .gray
        case .assignment:
            return .blue
        case .update:
            return .orange
        }
    }
}
