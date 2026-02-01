//
//  KMeansDetail.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 05.01.26.
//
import SwiftUI

struct KMeansDetail: View {
    @ObservedObject var vm: KMeansVM
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Unsupervised Learning: K-Means")
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                    
                    Text("Clustering-Algorithmus")
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
                    phase: vm.currentPhase,
                    datasetType: vm.datasetType
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
