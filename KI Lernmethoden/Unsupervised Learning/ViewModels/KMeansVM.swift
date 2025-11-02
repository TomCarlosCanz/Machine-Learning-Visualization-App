//
//  KMeansVM.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 05.01.26.
//
import SwiftUI
import Combine

enum ExecutionMode: String, CaseIterable, Identifiable {
    case continuous = "Kontinuierlich"
    case stepByStep = "Schritt für Schritt"
    
    var id: String { rawValue }
}

@MainActor
final class KMeansVM: ObservableObject {
    
    // VARIABLES
    @Published var points: [ClusterPoint] = []
    @Published var centroids: [Centroid] = []
    @Published var k: Int = 3
    @Published var currentIteration: Int = 0
    @Published var maxIterations: Int = 10
    @Published var isRunning = false
    @Published var speed: Double = 1.5 // seconds per step
    @Published var currentPhase: ClusteringPhase = .idle
    @Published var datasetType: DatasetType = .blobs
    @Published var hasConverged: Bool = false
    @Published var executionMode: ExecutionMode = .continuous
    
    @Published var inertia: Double = 0.0 // Sum of squared distances to centroids
    
    private var timerCancellable: AnyCancellable?
    private var previousAssignments: [Int] = []
    private var isAssignmentPhase = true
    
    init() { generateData() }
    
    func generateData() {
        let n = 100
        var pts: [ClusterPoint] = []
        
        switch datasetType {
        case .blobs:
            // Three well-separated blobs
            let centers = [(0.3, 0.3), (0.7, 0.7), (0.3, 0.7)]
            for center in centers {
                for _ in 0..<(n/3) {
                    let x = center.0 + Double.random(in: -0.1...0.1)
                    let y = center.1 + Double.random(in: -0.1...0.1)
                    pts.append(ClusterPoint(x: x, y: y))
                }
            }
            
        case .random:
            // Completely random
            for _ in 0..<n {
                pts.append(ClusterPoint(x: Double.random(in: 0.1...0.9), y: Double.random(in: 0.1...0.9)))
            }
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
            points = pts
            centroids.removeAll()
            currentIteration = 0
            currentPhase = .idle
            hasConverged = false
            inertia = 0.0
            previousAssignments = Array(repeating: -1, count: pts.count)
        }
    }
    
    func initializeCentroids() {
        // Use K-Means++ initialization for better centroid placement
        var newCentroids: [Centroid] = []
        
        if points.isEmpty { return }
        
        // Choose first centroid randomly
        let firstPoint = points.randomElement()!
        newCentroids.append(Centroid(x: firstPoint.x, y: firstPoint.y, clusterId: 0))
        
        // Choose remaining centroids based on distance from existing ones
        for i in 1..<k {
            var maxMinDist = 0.0
            var bestPoint = points[0]
            
            // For each point, find distance to nearest centroid
            for point in points {
                var minDist = Double.infinity
                for centroid in newCentroids {
                    let dist = distance((point.x, point.y), (centroid.x, centroid.y))
                    minDist = min(minDist, dist)
                }
                
                // Keep track of point with maximum minimum distance
                if minDist > maxMinDist {
                    maxMinDist = minDist
                    bestPoint = point
                }
            }
            
            newCentroids.append(Centroid(x: bestPoint.x, y: bestPoint.y, clusterId: i))
        }
        
        withAnimation {
            centroids = newCentroids
        }
    }
    
    func distance(_ p1: (x: Double, y: Double), _ p2: (x: Double, y: Double)) -> Double {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx*dx + dy*dy)
    }
    
    func assignPointsToClusters() {
        // Assignment step: assign each point to nearest centroid
        for i in 0..<points.count {
            var minDist = Double.infinity
            var nearestCluster = 0
            
            for centroid in centroids {
                let dist = distance((points[i].x, points[i].y), (centroid.x, centroid.y))
                if dist < minDist {
                    minDist = dist
                    nearestCluster = centroid.clusterId
                }
            }
            
            points[i].clusterId = nearestCluster
        }
    }
    
    func updateCentroids() {
        // Update step: move centroids to mean of their clusters
        var newCentroids: [Centroid] = []
        
        for centroid in centroids {
            let clusterPoints = points.filter { $0.clusterId == centroid.clusterId }
            
            if clusterPoints.isEmpty {
                // Keep centroid at same position if no points assigned
                newCentroids.append(centroid)
            } else {
                let meanX = clusterPoints.map { $0.x }.reduce(0, +) / Double(clusterPoints.count)
                let meanY = clusterPoints.map { $0.y }.reduce(0, +) / Double(clusterPoints.count)
                newCentroids.append(Centroid(x: meanX, y: meanY, clusterId: centroid.clusterId))
            }
        }
        
        centroids = newCentroids
    }
    
    func calculateInertia() -> Double {
        var totalInertia = 0.0
        
        for point in points {
            if let centroid = centroids.first(where: { $0.clusterId == point.clusterId }) {
                let dist = distance((point.x, point.y), (centroid.x, centroid.y))
                totalInertia += dist * dist
            }
        }
        
        return totalInertia
    }
    
    func checkConvergence() -> Bool {
        // Check if assignments changed
        let currentAssignments = points.map { $0.clusterId }
        let converged = currentAssignments == previousAssignments
        previousAssignments = currentAssignments
        return converged
    }
    
    // MARK: - Main Entry Point
    
    func runKMeans() {
        guard !isRunning else { return }
        isRunning = true
        currentIteration = 0
        hasConverged = false
        
        // Initialize centroids
        initializeCentroids()
        
        // Clear previous assignments
        previousAssignments = []
        isAssignmentPhase = true
        
        if executionMode == .continuous {
            runContinuous()
        } else {
            // Step-by-step mode: start with assignment phase
            withAnimation {
                currentPhase = .assignment
            }
        }
    }
    
    // MARK: - Step-by-Step Mode
    
    func nextStep() {
        guard isRunning else { return }
        guard !hasConverged && currentIteration < maxIterations else {
            isRunning = false
            currentPhase = .idle
            return
        }
        
        switch currentPhase {
        case .idle:
            // Should not happen, but handle it
            withAnimation {
                currentPhase = .assignment
            }
            
        case .assignment:
            // Step 1: Assign points to nearest centroid
            assignPointsToClusters()
            
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPhase = .update
            }
            
        case .update:
            // Step 2: Move centroids to cluster means
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                updateCentroids()
            }
            
            // Calculate cluster quality
            inertia = calculateInertia()
            
            // Check convergence
            if checkConvergence() {
                hasConverged = true
                withAnimation {
                    currentPhase = .idle
                    isRunning = false
                }
            } else {
                currentIteration += 1
                
                // Check if we're done with iterations
                if currentIteration >= maxIterations {
                    withAnimation {
                        currentPhase = .idle
                        isRunning = false
                    }
                } else {
                    // Move to next iteration
                    withAnimation {
                        currentPhase = .assignment
                    }
                }
            }
        }
    }
    
    func stopStepMode() {
        isRunning = false
        withAnimation {
            currentPhase = .idle
        }
    }
    
    // MARK: - Continuous Mode
    
    func stopTraining() {
        isRunning = false
        timerCancellable?.cancel()
        withAnimation {
            currentPhase = .idle
        }
    }
    
    private func runContinuous() {
        var lastUpdateTime = Date()
        
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            
            let now = Date()
            guard now.timeIntervalSince(lastUpdateTime) >= self.speed else { return }
            lastUpdateTime = now
            
            // Check if we're done
            if self.hasConverged || self.currentIteration >= self.maxIterations {
                self.isRunning = false
                self.currentPhase = .idle
                self.timerCancellable?.cancel()
                return
            }
            
            if self.isAssignmentPhase {
                // ASSIGNMENT PHASE
                withAnimation(.easeInOut(duration: self.speed * 0.3)) {
                    self.currentPhase = .assignment
                }
                
                self.assignPointsToClusters()
                
                self.isAssignmentPhase = false
            } else {
                // UPDATE PHASE
                withAnimation(.easeInOut(duration: self.speed * 0.3)) {
                    self.currentPhase = .update
                }
                
                withAnimation(.spring(response: self.speed * 0.6, dampingFraction: 0.7)) {
                    self.updateCentroids()
                }
                
                // Calculate cluster quality
                self.inertia = self.calculateInertia()
                
                // Check convergence AFTER updating centroids
                if self.checkConvergence() {
                    self.hasConverged = true
                }
                
                self.currentIteration += 1
                self.isAssignmentPhase = true
            }
        }
    }
    
    func reset() {
        isRunning = false
        timerCancellable?.cancel()
        isAssignmentPhase = true
        withAnimation {
            currentPhase = .idle
        }
        generateData()
    }
}
