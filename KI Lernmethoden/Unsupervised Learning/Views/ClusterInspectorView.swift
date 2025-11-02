//
//  ClusterInspectorView.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 05.01.26.
//
import SwiftUI

struct ClusterInspectorView: View {
    @ObservedObject var vm: KMeansVM
    
    var body: some View {
        Form {
            Section("Ausführungsmodus") {
                Picker("Modus", selection: $vm.executionMode) {
                    ForEach(ExecutionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .disabled(vm.isRunning)
                
                if vm.executionMode == .stepByStep {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Im Schritt-für-Schritt Modus:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("• Punkte zu Zentroiden zuweisen")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("• Zentroide verschieben")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("• Wiederholen bis Konvergenz")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            
            Section {
                Picker("Datenverteilung", selection: $vm.datasetType) {
                    ForEach(DatasetType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .disabled(vm.isRunning)
                .onChange(of: vm.datasetType) { _, _ in
                    vm.generateData()
                }
            } header: {
                Text("Dataset")
            } footer: {
                Text(vm.datasetType.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("K-Means Parameter") {
                Stepper("K (Anzahl Cluster): \(vm.k)", value: $vm.k, in: 2...8)
                    .disabled(vm.isRunning)
                
                Text("Bestimmt, in wie viele Gruppen die Daten aufgeteilt werden.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if vm.executionMode == .continuous {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Geschwindigkeit")
                            Spacer()
                            Text(speedLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $vm.speed, in: 0.5...3.0, step: 0.1)
                    }
                }
            }
            
            Section("Leistung") {
                LabeledContent("Iteration") {
                    Text("\(vm.currentIteration)/\(vm.maxIterations)").monospaced()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    LabeledContent("Inertia") {
                        HStack(spacing: 6) {
                            Text(vm.inertia, format: .number.precision(.fractionLength(3)))
                                .monospaced()
                            
                            if vm.inertia > 0 {
                                Image(systemName: inertiaIcon)
                                    .foregroundStyle(inertiaColor)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    if vm.inertia > 0 {
                        Text(inertiaQuality)
                            .font(.caption2)
                            .foregroundStyle(inertiaColor)
                    } else {
                        Text("Inertia misst die Cluster-Qualität. Niedriger = besser.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if vm.isRunning {
                    LabeledContent("Aktueller Schritt") {
                        Text(currentStepDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                LabeledContent("Status") {
                    if vm.hasConverged {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Konvergiert")
                        }
                    } else if vm.isRunning {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.blue)
                            Text("Läuft...")
                        }
                    } else {
                        Text("Bereit")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Dataset") {
                LabeledContent("Datenpunkte") {
                    Text("\(vm.points.count) Punkte").monospaced()
                }
                
                LabeledContent("Zentroide") {
                    Text("\(vm.centroids.count) Cluster").monospaced()
                }
                
                Text("Alle Datenpunkte werden für das Clustering verwendet.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .navigationTitle("Inspector")
    }
    
    var currentStepDescription: String {
        switch vm.currentPhase {
        case .idle:
            return "Bereit zum Start"
        case .assignment:
            return "Punkte werden zugewiesen"
        case .update:
            return "Zentroide werden verschoben"
        }
    }
    
    var speedLabel: String {
        switch vm.speed {
        case 0.5...1.0:
            return "Schnell (\(String(format: "%.1f", vm.speed))s pro Schritt)"
        case 1.01...2.0:
            return "Normal (\(String(format: "%.1f", vm.speed))s pro Schritt)"
        case 2.01...2.5:
            return "Langsam (\(String(format: "%.1f", vm.speed))s pro Schritt)"
        default:
            return "Sehr langsam (\(String(format: "%.1f", vm.speed))s pro Schritt)"
        }
    }
    
    var inertiaQuality: String {
        let inertia = vm.inertia
        if inertia < 0.5 {
            return "Ausgezeichnete Cluster-Qualität - sehr kompakt"
        } else if inertia < 1.5 {
            return "Gute Cluster-Qualität - klar getrennt"
        } else if inertia < 3.0 {
            return "Akzeptable Cluster-Qualität"
        } else {
            return "Schlechte Cluster-Qualität - Punkte weit verstreut"
        }
    }
    
    var inertiaIcon: String {
        let inertia = vm.inertia
        if inertia < 0.5 {
            return "star.fill"
        } else if inertia < 1.5 {
            return "checkmark.circle.fill"
        } else if inertia < 3.0 {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    var inertiaColor: Color {
        let inertia = vm.inertia
        if inertia < 0.5 {
            return .green
        } else if inertia < 1.5 {
            return .green
        } else if inertia < 3.0 {
            return .orange
        } else {
            return .red
        }
    }
}
