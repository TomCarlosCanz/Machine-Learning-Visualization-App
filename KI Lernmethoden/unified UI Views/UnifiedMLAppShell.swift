//
//  UnifiedMLAppShell.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 05.01.26.
//
import SwiftUI

struct UnifiedMLAppShell: View {
    @StateObject private var regressionVM = RegressionVM()
    @StateObject private var kmeansVM = KMeansVM()
    @State private var selection: MLSidebarItem? = .supervised
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            MLSidebarView(selection: $selection)
        } detail: {
            Group {
                switch selection {
                case .supervised, .none:
                    SupervisedLearningView(vm: regressionVM)
                case .unsupervised:
                    UnsupervisedLearningView(vm: kmeansVM)
                case .settings:
                    SettingsView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if columnVisibility == .detailOnly {
                        Button {
                            withAnimation {
                                columnVisibility = .all
                            }
                        } label: {
                            Image(systemName: "sidebar.left")
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    resetButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    var resetButton: some View {
        switch selection {
        case .supervised:
            Button("Reset") {
                regressionVM.generateData()
            }
            .disabled(regressionVM.isTraining || regressionVM.isStepMode)
        case .unsupervised:
            Button("Reset") {
                kmeansVM.reset()
            }
            .disabled(kmeansVM.isRunning)
        case .settings, .none:
            EmptyView()
        }
    }
}

// MARK: - Supervised Learning View
struct SupervisedLearningView: View {
    @ObservedObject var vm: RegressionVM
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Supervised Learning")
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                    
                    Text("Gradient Descent für Lineare Regression")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Training mode picker
                Picker("Trainingsmodus", selection: $vm.trainingMode) {
                    ForEach(TrainingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .disabled(vm.isTraining || vm.isStepMode)

                PhaseIndicator(
                    phase: vm.currentPhase,
                    currentEpoch: vm.currentEpoch,
                    totalEpochs: vm.epochs,
                    gradientMagnitude: vm.gradientMagnitude,
                    isStepMode: vm.isStepMode
                )
                .padding(.horizontal)

                RegressionPlot(
                    points: vm.points,
                    a: vm.slope,
                    b: vm.intercept,
                    phase: vm.currentPhase,
                    predictions: vm.currentPredictions,
                    showErrorLines: vm.showErrorLines
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Loss Verlauf")
                            .font(.headline)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(.orange).frame(width: 8, height: 8)
                            Text("MSE").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    LossSparkline(values: vm.lossHistory)
                }
                .padding(.horizontal)
                
                ScenarioEvaluation(vm: vm)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if vm.trainingMode == .continuous {
                    // Continuous mode button
                    if vm.isTraining {
                        Button {
                            vm.stopTraining()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                        }
                    } else {
                        Button {
                            vm.fitGradientDescent()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text("Train")
                            }
                        }
                    }
                } else {
                    // Step-by-step mode buttons
                    if vm.isStepMode {
                        Button {
                            vm.stopStepMode()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                Text("Reset")
                            }
                        }
                        .tint(.red)
                        
                        Button {
                            vm.nextStep()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right")
                                Text(vm.currentEpoch >= vm.epochs ? "Fertig" : "Weiter")
                            }
                        }
                        .disabled(vm.currentEpoch >= vm.epochs)
                    } else {
                        Button {
                            vm.startStepMode()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text("Start")
                            }
                        }
                    }
                }
            }
        }
        .inspector(isPresented: .constant(true)) {
            InspectorView(vm: vm)
        }
    }
}

// MARK: - Unsupervised Learning View
struct UnsupervisedLearningView: View {
    @ObservedObject var vm: KMeansVM
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Unsupervised Learning")
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                    
                    Text("K-Means Clustering Algorithmus")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Execution mode picker
                Picker("Ausführungsmodus", selection: $vm.executionMode) {
                    ForEach(ExecutionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .disabled(vm.isRunning)

                ClusterPhaseIndicator(
                    phase: vm.currentPhase,
                    currentIteration: vm.currentIteration,
                    maxIterations: vm.maxIterations,
                    hasConverged: vm.hasConverged
                )
                .padding(.horizontal)

                ClusterPlot(
                    points: vm.points,
                    centroids: vm.centroids,
                    phase: vm.currentPhase
                )
                .padding(.horizontal)
                
                ClusterStatistics(vm: vm)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if vm.executionMode == .continuous {
                    // Continuous mode button
                    if vm.isRunning {
                        Button {
                            vm.stopTraining()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                        }
                    } else {
                        Button {
                            vm.runKMeans()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text("Start")
                            }
                        }
                    }
                } else {
                    // Step-by-step mode buttons
                    if vm.isRunning {
                        Button {
                            vm.stopStepMode()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                Text("Reset")
                            }
                        }
                        .tint(.red)
                        
                        Button {
                            vm.nextStep()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right")
                                Text(vm.hasConverged || vm.currentIteration >= vm.maxIterations ? "Fertig" : "Weiter")
                            }
                        }
                        .disabled(vm.hasConverged || vm.currentIteration >= vm.maxIterations)
                    } else {
                        Button {
                            vm.runKMeans()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text("Start")
                            }
                        }
                    }
                }
            }
        }
        .inspector(isPresented: .constant(true)) {
            ClusterInspectorView(vm: vm)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Machine Learning Labor")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 12) {
                SettingCard(
                    icon: "chart.xyaxis.line",
                    title: "Supervised Learning",
                    description: "Lerne aus gelabelten Daten mit Gradient Descent",
                    color: .orange
                )
                
                SettingCard(
                    icon: "circle.hexagongrid.fill",
                    title: "Unsupervised Learning",
                    description: "Entdecke Muster in ungelabelten Daten mit K-Means",
                    color: .blue
                )
            }
            .padding(.horizontal)
            
            Text("Wähle ein Lernverfahren aus der Sidebar")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingCard: View {
    var icon: String
    var title: String
    var description: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(color)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
    }
}
