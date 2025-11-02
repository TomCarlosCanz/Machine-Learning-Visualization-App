//
//  RegressionDetail.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI

struct RegressionDetail: View {
    @ObservedObject var vm: RegressionVM
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Supervised Learning: Gradient Descent")
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
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
