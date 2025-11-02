//
//  SidebarItem.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI

// MARK: - Sidebar & Inspector (iPad idioms)
enum SidebarItem: String, CaseIterable, Identifiable {
    case regression = "Regression"
    case settings = "Einstellungen"
    var id: String { rawValue }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    
    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.rawValue, systemImage: item == .regression ? "chart.xyaxis.line" : "slider.horizontal.3")
        }
        .navigationTitle("KI-Labor")
        .listStyle(.sidebar)
    }
}

struct InspectorView: View {
    @ObservedObject var vm: RegressionVM
    
    var body: some View {
        Form {
            Section("Trainingsmodus") {
                Picker("Modus", selection: $vm.trainingMode) {
                    ForEach(TrainingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .disabled(vm.isTraining || vm.isStepMode)
                
                if vm.trainingMode == .stepByStep {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Im Schritt-für-Schritt Modus:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("• Vorhersage machen")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("• Abweichung berechnen")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("• Daraus lernen")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            
            Section("Szenario") {
                Picker("Datensatz", selection: $vm.selectedScenario) {
                    ForEach(Scenario.allCases) { scenario in
                        Text(scenario.rawValue).tag(scenario)
                    }
                }
                .disabled(vm.isTraining || vm.isStepMode)
                .onChange(of: vm.selectedScenario) { _, _ in
                    vm.generateData()
                }
                
                Text(vm.selectedScenario.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Training Parameter") {
                if vm.trainingMode == .continuous {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Geschwindigkeit")
                            Spacer()
                            Text(speedLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $vm.speed, in: 0.01...1.0, step: 0.01)
                    }
                }
            }
       
            Section("Modellparameter") {
                LabeledContent("a (Steigung)") {
                    Text(vm.slope, format: .number.precision(.fractionLength(3))).monospaced()
                }
                LabeledContent("b (Intercept)") {
                    Text(vm.intercept, format: .number.precision(.fractionLength(3))).monospaced()
                }
            }
            
            Section("Leistung") {
                LabeledContent("Epoche") {
                    Text("\(vm.currentEpoch)/600").monospaced()
                }
                LabeledContent("MSE (Loss)") {
                    Text(vm.trainLoss, format: .number.precision(.fractionLength(4))).monospaced()
                        .foregroundStyle(.orange)
                }
                
                if vm.isStepMode {
                    LabeledContent("Aktueller Schritt") {
                        Text(currentStepDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Dataset") {
                LabeledContent("Datenpunkte") {
                    Text("\(vm.points.count) Punkte").monospaced()
                        .foregroundStyle(.orange)
                }
                
                Text("Alle Datenpunkte werden für das Training verwendet.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .navigationTitle("Inspector")
    }
    
    var speedLabel: String {
        switch vm.speed {
        case 0.01...0.05:
            return "Sehr schnell (\(String(format: "%.2f", vm.speed))s)"
        case 0.051...0.15:
            return "Schnell (\(String(format: "%.2f", vm.speed))s)"
        case 0.151...0.3:
            return "Normal (\(String(format: "%.2f", vm.speed))s)"
        case 0.301...0.6:
            return "Langsam (\(String(format: "%.2f", vm.speed))s)"
        default:
            return "Sehr langsam (\(String(format: "%.2f", vm.speed))s)"
        }
    }
    
    var currentStepDescription: String {
        switch vm.currentPhase {
        case .idle:
            return "Bereit zum Start"
        case .makingPrediction:
            return "Vorhersagen werden erstellt"
        case .calculatingError:
            return "Abweichungen werden berechnet"
        case .learningFromError:
            return "Parameter werden angepasst"
        default:
            return "-"
        }
    }
}
