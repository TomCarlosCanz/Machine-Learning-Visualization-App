//
//  SupervisedLearningViewModel.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI
import Combine

@MainActor
final class RegressionVM: ObservableObject {
    
    //VARIABLES (maybe too many @Published variables honestly haha)
    @Published var points: [SamplePoint] = []
    @Published var slope: Double = 0
    @Published var intercept: Double = 0
    @Published var trainLoss: Double = 0
    @Published var lr: Double = 0.05
    @Published var epochs: Int = 600
    @Published var currentEpoch: Int = 0
    @Published var isTraining = false
    @Published var speed: Double = 0.1 // seconds per epoch
    @Published var currentPhase: TrainingPhase = .idle
    @Published var lossHistory: [Double] = []
    @Published var gradientMagnitude: Double = 0
    @Published var selectedScenario: Scenario = .weather
    
    @Published var trainingMode: TrainingMode = .continuous
    @Published var isStepMode = false
    
    @Published var currentPredictions: [Double] = []
    @Published var currentErrors: [Double] = []
    @Published var showErrorLines = false
    
    private var timerCancellable: AnyCancellable?
    
    private var stepA: Double = 0
    private var stepB: Double = 0
    private var stepGradA: Double = 0
    private var stepGradB: Double = 0

    init() { generateData() }

    func generateData(n: Int = 56) {
        let scenario = selectedScenario
        var pts: [SamplePoint] = []
        let xs = stride(from: 0.0, through: 1.0, by: 1.0/Double(n-1))
        
        //Generate points - all used for training
        for x in xs {
            let y = scenario.trueSlope * x + scenario.trueIntercept + Double.random(in: -scenario.noise...scenario.noise)
            pts.append(.init(x: x, y: y))
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
            points = pts
            slope = 0
            intercept = 0
            lossHistory.removeAll()
            currentEpoch = 0
            currentPhase = .idle
            gradientMagnitude = 0
            currentPredictions = []
            currentErrors = []
            showErrorLines = false
        }
        
        trainLoss = mse(a: slope, b: intercept, points: points)
    }

    //formula for calculating error rate (MSE)
    func mse(a: Double, b: Double, points: [SamplePoint]) -> Double {
        guard !points.isEmpty else { return 0 }
        let n = Double(points.count)
        let s = points.reduce(0.0) { acc, p in
            let e = (a*p.x + b) - p.y
            return acc + e*e
        }
        return s / n
    }
    
//reset of variables (step 1)
    func startStepMode() {
        isStepMode = true
        currentEpoch = 0
        stepA = slope
        stepB = intercept
        currentPhase = .idle
        lossHistory.removeAll()
        currentPredictions = []
        currentErrors = []
        showErrorLines = false
        
        withAnimation {
            currentPhase = .makingPrediction
        }
    }
    
    // start process
    func nextStep() {
        guard isStepMode else { return }
        
        switch currentPhase {
        case .idle:
            withAnimation {
                currentPhase = .makingPrediction
            }
            
        case .makingPrediction:
            // Step 1: Make predictions with current model
            let predictions = points.map { p in
                stepA * p.x + stepB
            }
            
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPredictions = predictions
                currentPhase = .calculatingError
            }
            
        case .calculatingError:
            // Step 2: Calculate errors
            let errors = zip(points, currentPredictions).map { point, prediction in
                prediction - point.y
            }
            
            withAnimation(.easeInOut(duration: 0.4)) {
                currentErrors = errors
                showErrorLines = true
                currentPhase = .learningFromError
            }
            
        case .learningFromError:
            // Step 3: Learn from errors
            let pts = points
            let n = Double(pts.count)
            var da = 0.0, db = 0.0
            
            for (i, p) in pts.enumerated() {
                let err = currentErrors[i]
                da += err * p.x
                db += err
            }
            
            stepGradA = (2.0/n) * da
            stepGradB = (2.0/n) * db
            
            let gradMag = sqrt(stepGradA * stepGradA + stepGradB * stepGradB)
            gradientMagnitude = gradMag
            
            // Update parameters
            stepA -= lr * stepGradA
            stepB -= lr * stepGradB
            
            // Calculate mse
            let tl = mse(a: stepA, b: stepB, points: points)
            trainLoss = tl
            lossHistory.append(tl)
            
            if lossHistory.count > 600 {
                lossHistory.removeFirst(lossHistory.count - 600)
            }
            
            withAnimation(.easeOut(duration: 0.4)) {
                slope = stepA
                intercept = stepB
                showErrorLines = false
                currentPredictions = []
                currentErrors = []
            }
            
            currentEpoch += 1
            
            // Check if we're done
            if currentEpoch >= epochs {
                withAnimation {
                    currentPhase = .idle
                    isStepMode = false
                    gradientMagnitude = 0
                }
            } else {
                withAnimation {
                    currentPhase = .makingPrediction
                }
            }
            
            //basically this is here for compliance with TrainingPhase
        case .training, .testing, .adjusting:
            break
        }
    }
    
    //pause button
    func stopStepMode() {
        isStepMode = false
        withAnimation {
            currentPhase = .idle
            gradientMagnitude = 0
            currentPredictions = []
            currentErrors = []
            showErrorLines = false
        }
    }

    
    //Make corrections (step 3)
    func fitGradientDescent() {
        guard !isTraining else { return }
        isTraining = true
        currentEpoch = 0
        
        var a = slope
        var b = intercept
        
        let pts = points
        let n = Double(pts.count)
        
        var lastUpdateTime = Date()
        
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            
            // Checks speed
            let now = Date()
            guard now.timeIntervalSince(lastUpdateTime) >= self.speed else { return }
            lastUpdateTime = now
            
            // Check if done with epochs
            if self.currentEpoch >= self.epochs {
                self.isTraining = false
                self.currentPhase = .idle
                self.gradientMagnitude = 0
                self.timerCancellable?.cancel()
                return
            }
            
            // TRAINING PHASE
            withAnimation(.easeInOut(duration: self.speed * 0.4)) {
                self.currentPhase = .training
            }
            
            // Compute gradients on all data
            var da = 0.0, db = 0.0
            for p in pts {
                let yhat = a*p.x + b
                let err = yhat - p.y
                da += err*p.x
                db += err
            }
            
            // Scale it
            da = (2.0/n) * da
            db = (2.0/n) * db
            
            // Calculate gradient magnitude for visualization
            let gradMag = sqrt(da*da + db*db)
            self.gradientMagnitude = gradMag
            
            // Update parameters
            a -= self.lr * da
            b -= self.lr * db
            
            withAnimation(.easeOut(duration: speed * 0.8)) {
                self.slope = a
                self.intercept = b
            }
            
            // Calculate loss
            let tl = self.mse(a: a, b: b, points: self.points)
            self.trainLoss = tl
            self.lossHistory.append(tl)
            
            // Trim history if too long
            if self.lossHistory.count > 600 {
                self.lossHistory.removeFirst(self.lossHistory.count - 600)
            }
            
            // Move to next epoch
            self.currentEpoch += 1
        }
    }
    
    
    //stop function (doesn't reset)
    func stopTraining() {
        isTraining = false
        timerCancellable?.cancel()
        withAnimation {
            currentPhase = .idle
            gradientMagnitude = 0
        }
    }
}

enum TrainingMode: String, CaseIterable {
    case continuous = "Kontinuierlich"
    case stepByStep = "Schritt für Schritt"
}

/*
 WHAT THIS CODE DOES:
 - this is the actual Supervised Learning training method (Gradient Descent)
 - nextStep is for step by step
 - fitGradientDescent is for continuous mode
 */
