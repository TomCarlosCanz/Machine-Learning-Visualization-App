//
//  Position.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 17.01.26.
//
import SwiftUI
import Combine

// MARK: - Model
struct Position: Hashable, Codable {
    let x: Int
    let y: Int
}

enum CellType {
    case empty
    case wall
    case start
    case goal
    case agent
}

enum Action: Int, CaseIterable {
    case up = 0
    case down = 1
    case left = 2
    case right = 3
    
    func delta() -> (dx: Int, dy: Int) {
        switch self {
        case .up: return (0, -1)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }
}

class QLearningAgent {
    private var qTable: [Position: [Action: Double]] = [:]
    private let learningRate: Double = 0.5  // High learning rate for faster updates
    private let discountFactor: Double = 0.95  // Higher gamma to value future rewards more
    private var epsilon: Double = 1.0  // Start with 100% exploration
    private let epsilonDecay: Double = 0.998  // Slower decay to explore more
    private let minEpsilon: Double = 0.05  // Keep some exploration
    
    func getQValue(state: Position, action: Action) -> Double {
        return qTable[state]?[action] ?? 0.0
    }
    
    func getBestAction(state: Position) -> Action {
        var bestAction = Action.up
        var bestValue = Double.leastNormalMagnitude
        
        for action in Action.allCases {
            let value = getQValue(state: state, action: action)
            if value > bestValue {
                bestValue = value
                bestAction = action
            }
        }
        return bestAction
    }
    
    func chooseAction(state: Position) -> Action {
        // Epsilon-greedy strategy
        if Double.random(in: 0...1) < epsilon {
            return Action.allCases.randomElement()!
        } else {
            return getBestAction(state: state)
        }
    }
    
    func update(state: Position, action: Action, reward: Double, nextState: Position) {
        let currentQ = getQValue(state: state, action: action)
        let maxNextQ = Action.allCases.map { getQValue(state: nextState, action: $0) }.max() ?? 0.0
        let newQ = currentQ + learningRate * (reward + discountFactor * maxNextQ - currentQ)
        
        if qTable[state] == nil {
            qTable[state] = [:]
        }
        qTable[state]?[action] = newQ
    }
    
    func decayEpsilon() {
        epsilon = max(minEpsilon, epsilon * epsilonDecay)
    }
    
    func getCurrentEpsilon() -> Double {
        return epsilon
    }
    
    func reset() {
        qTable.removeAll()
        epsilon = 1.0  // Start with 100% exploration
    }
}

// MARK: - Training Mode
enum RLTrainingMode: String, CaseIterable {
    case continuous = "Kontinuierlich"
    case stepByStep = "Schritt für Schritt"
}

// MARK: - Training Phase
enum RLTrainingPhase {
    case idle
    case makingMove
    case calculatingReward
    case updatingQTable
    case completed
    
    var description: String {
        switch self {
        case .idle: return "Bereit zu starten"
        case .makingMove: return "Agent wählt Aktion und bewegt sich"
        case .calculatingReward: return "Belohnung wird berechnet"
        case .updatingQTable: return "Q-Werte werden aktualisiert"
        case .completed: return "Episode abgeschlossen"
        }
    }
}

// MARK: - ViewModel
@MainActor
class MazeViewModel: ObservableObject {
    @Published var maze: [[CellType]] = []
    @Published var agentPosition: Position
    @Published var isTraining: Bool = false
    @Published var episode: Int = 0
    @Published var totalReward: Double = 0
    @Published var episodeRewards: [Double] = []
    @Published var movesInEpisode: Int = 0
    @Published var showPath: Bool = false
    @Published var bestPath: [Position] = []
    @Published var explorationRate: Double = 1.0
    @Published var successfulEpisodes: Int = 0
    @Published var successRate: Double = 0.0
    @Published var trainingSpeed: RLTrainingSpeed = .medium
    @Published var isDemoing: Bool = false
    @Published var trainingMode: RLTrainingMode = .continuous
    @Published var isStepMode: Bool = false
    @Published var currentPhase: RLTrainingPhase = .idle
    @Published var currentAction: Action?
    @Published var currentReward: Double = 0
    @Published var lastQValue: Double = 0
    @Published var newQValue: Double = 0
    @Published var lastMovePosition: Position?
    @Published var rewardPosition: Position?
    @Published var showRewardAnimation: Bool = false
    @Published var attemptedPosition: Position?
    @Published var agentAnimationState: AgentAnimationState = .idle
    
    enum AgentAnimationState {
        case idle
        case showingIntention  // Back and forth movement
        case shakingNo         // Hit wall - shake head
        case movingSuccess     // Successful move - slide to new position
    }
    @Published var isAnimatingIntention: Bool = false
    @Published var isAnimatingResult: Bool = false
    
    enum RLTrainingSpeed: String, CaseIterable {
        case slow = "Langsam"
        case medium = "Mittel"
        case fast = "Schnell"
        case instant = "Sofort"
        
        var delay: UInt64 {
            switch self {
            case .slow: return 100_000_000 // 100ms
            case .medium: return 10_000_000 // 10ms
            case .fast: return 1_000_000 // 1ms
            case .instant: return 0 // No delay
            }
        }
        
        var visualizationFrequency: Int {
            switch self {
            case .slow: return 1 // Every episode
            case .medium: return 10 // Every 10 episodes
            case .fast: return 50 // Every 50 episodes
            case .instant: return 100 // Every 100 episodes
            }
        }
    }
    
    private let agent = QLearningAgent()
    private let startPosition: Position
    private let goalPosition: Position
    private let gridSize: Int = 10
    private var trainingTask: Task<Void, Never>?
    
    init() {
        self.startPosition = Position(x: 0, y: 0)
        self.goalPosition = Position(x: 9, y: 9)
        self.agentPosition = startPosition
        setupMaze()
    }
    
    private func setupMaze() {
        // Create a highly intricate maze with multiple paths, dead ends, and complex routing
        let mazePattern = [
            [0, 0, 0, 1, 0, 0, 0, 1, 1, 1],
            [1, 1, 0, 1, 0, 1, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 1, 1, 1, 0, 1],
            [1, 0, 1, 1, 1, 1, 1, 1, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 1, 1, 1, 0, 1, 1, 1, 0, 1],
            [1, 0, 0, 0, 0, 1, 0, 0, 0, 1],
            [1, 0, 1, 1, 1, 1, 0, 1, 1, 1],
            [1, 0, 0, 0, 0, 0, 0, 1, 1, 1],
            [1, 1, 1, 1, 1, 1, 0, 0, 0, 0]
        ]
        
        // Convert to our CellType enum
        maze = mazePattern.map { row in
            row.map { $0 == 0 ? CellType.empty : CellType.wall }
        }
        
        maze[startPosition.y][startPosition.x] = .start
        maze[goalPosition.y][goalPosition.x] = .goal
    }
    
    func getCellType(x: Int, y: Int) -> CellType {
        if agentPosition.x == x && agentPosition.y == y {
            return .agent
        }
        return maze[y][x]
    }
    
    func startTraining() {
        guard !isTraining else { return }
        
        if trainingMode == .stepByStep {
            // Step-by-step mode doesn't auto-train
            return
        }
        
        isTraining = true
        episode = 0
        episodeRewards = []
        successfulEpisodes = 0
        
        trainingTask = Task {
            while !Task.isCancelled {
                await runEpisode()
                
                // Only add delay and update UI based on speed setting
                if episode % trainingSpeed.visualizationFrequency == 0 {
                    try? await Task.sleep(nanoseconds: trainingSpeed.delay)
                }
            }
            isTraining = false
            await generateBestPath()
        }
    }
    
    func startStepMode() {
        isStepMode = true
        currentPhase = .idle
        episode = 0
        agentPosition = startPosition
        totalReward = 0
        movesInEpisode = 0
        currentAction = nil
        currentReward = 0
        lastQValue = 0
        newQValue = 0
        lastMovePosition = nil
        rewardPosition = nil
        showRewardAnimation = false
        attemptedPosition = nil
        isAnimatingIntention = false
        isAnimatingResult = false
    }
    
    func stopStepMode() {
        isStepMode = false
        currentPhase = .idle
        agentPosition = startPosition
        episode = 0
        totalReward = 0
        movesInEpisode = 0
        currentAction = nil
        currentReward = 0
        lastQValue = 0
        newQValue = 0
        lastMovePosition = nil
        rewardPosition = nil
        showRewardAnimation = false
        attemptedPosition = nil
        isAnimatingIntention = false
        isAnimatingResult = false
    }
    
    func nextStep() {
        guard isStepMode else { return }
        
        // Execute next step in the training process
        switch currentPhase {
        case .idle:
            // Phase 1: Choose action and animate intention (ball moves back and forth)
            currentPhase = .makingMove
            let currentState = agentPosition
            currentAction = agent.chooseAction(state: currentState)
            lastQValue = agent.getQValue(state: currentState, action: currentAction!)
            
            // Calculate where the agent wants to move
            if let action = currentAction {
                let delta = action.delta()
                let targetX = agentPosition.x + delta.dx
                let targetY = agentPosition.y + delta.dy
                
                if targetY >= 0 && targetY < gridSize && targetX >= 0 && targetX < gridSize {
                    attemptedPosition = Position(x: targetX, y: targetY)
                } else {
                    attemptedPosition = agentPosition // Hitting boundary
                }
            }
            
            // Start intention animation (ball moves back and forth)
            isAnimatingIntention = true
            
        case .makingMove:
            // Phase 2: Stop intention animation, execute move, and animate result
            isAnimatingIntention = false
            currentPhase = .calculatingReward
            guard let action = currentAction else { return }
            
            lastMovePosition = agentPosition // Store where we were
            let (newPosition, reward) = performAction(action)
            
            // Check if this was a wall collision
            let hitWall = (newPosition == agentPosition)
            
            // Visual feedback
            rewardPosition = hitWall ? attemptedPosition : newPosition
            currentReward = reward
            showRewardAnimation = true
            
            agentPosition = newPosition
            totalReward += reward
            movesInEpisode += 1
            
            // Start result animation (shake for wrong, move for correct)
            isAnimatingResult = true
            
        case .calculatingReward:
            // Phase 3: Stop result animation and show Q-table update
            isAnimatingResult = false
            currentPhase = .updatingQTable
            guard let action = currentAction else { return }
            let currentState = Position(x: agentPosition.x, y: agentPosition.y)
            
            // Get old position (before the move)
            let delta = action.delta()
            let oldPosition = Position(x: agentPosition.x - delta.dx, y: agentPosition.y - delta.dy)
            
            agent.update(state: oldPosition, action: action, reward: currentReward, nextState: currentState)
            newQValue = agent.getQValue(state: oldPosition, action: action)
            
        case .updatingQTable:
            // Phase 4: Clear visuals and check if episode is complete
            showRewardAnimation = false
            rewardPosition = nil
            lastMovePosition = nil
            attemptedPosition = nil
            
            if agentPosition == goalPosition || movesInEpisode >= 1000 {
                // Episode complete - start new episode automatically
                if agentPosition == goalPosition {
                    successfulEpisodes += 1
                }
                
                agent.decayEpsilon()
                episode += 1
                episodeRewards.append(totalReward)
                successRate = Double(successfulEpisodes) / Double(episode)
                explorationRate = agent.getCurrentEpsilon()
                
                if episodeRewards.count > 100 {
                    episodeRewards.removeFirst()
                }
                
                // Reset for new episode
                agentPosition = startPosition
                totalReward = 0
                movesInEpisode = 0
                currentAction = nil
                currentPhase = .idle
            } else {
                // Continue with next step
                currentPhase = .idle
                currentAction = nil
            }
            
        case .completed:
            break
        }
    }
    
    func stopTraining() {
        trainingTask?.cancel()
        isTraining = false
    }
    
    func reset() {
        stopTraining()
        agent.reset()
        agentPosition = startPosition
        episode = 0
        totalReward = 0
        episodeRewards = []
        movesInEpisode = 0
        bestPath = []
        showPath = false
        explorationRate = 1.0
        successfulEpisodes = 0
        successRate = 0.0
        isDemoing = false
        isStepMode = false
        currentPhase = .idle
        currentAction = nil
        currentReward = 0
        lastQValue = 0
        newQValue = 0
        lastMovePosition = nil
        rewardPosition = nil
        showRewardAnimation = false
        attemptedPosition = nil
        isAnimatingIntention = false
        isAnimatingResult = false
    }
    
    private func runEpisode() async {
        agentPosition = startPosition
        var currentReward: Double = 0
        var moves = 0
        let maxMoves = 1000  // Increased to give much more time to explore
        
        while agentPosition != goalPosition && moves < maxMoves {
            let currentState = agentPosition
            let action = agent.chooseAction(state: currentState)
            let (newPosition, reward) = performAction(action)
            
            agent.update(state: currentState, action: action, reward: reward, nextState: newPosition)
            agentPosition = newPosition
            currentReward += reward
            moves += 1
            
            // Only visualize movement based on speed setting
            if episode % trainingSpeed.visualizationFrequency == 0 {
                try? await Task.sleep(nanoseconds: trainingSpeed.delay / 10)
            }
        }
        
        // Check if we successfully reached the goal
        if agentPosition == goalPosition {
            successfulEpisodes += 1
        }
        
        agent.decayEpsilon()
        episode += 1
        episodeRewards.append(currentReward)
        totalReward = currentReward
        movesInEpisode = moves
        explorationRate = agent.getCurrentEpsilon()
        successRate = Double(successfulEpisodes) / Double(episode)
        
        // Keep only last 100 rewards for display
        if episodeRewards.count > 100 {
            episodeRewards.removeFirst()
        }
    }
    
    private func performAction(_ action: Action) -> (Position, Double) {
        let delta = action.delta()
        let newX = agentPosition.x + delta.dx
        let newY = agentPosition.y + delta.dy
        
        // Check if new position is valid
        if newY >= 0 && newY < gridSize && newX >= 0 && newX < gridSize {
            let newPosition = Position(x: newX, y: newY)
            
            if maze[newY][newX] != .wall {
                // Reached goal
                if newPosition == goalPosition {
                    return (newPosition, 200.0)  // Huge reward for goal!
                }
                // Valid move - very small penalty
                return (newPosition, -0.01)
            }
        }
        
        // Hit wall or boundary - moderate penalty, stay in place
        return (agentPosition, -0.5)
    }
    
    func demonstrateLearning() async {
        guard !isTraining else { return }
        isDemoing = true
        agentPosition = startPosition
        movesInEpisode = 0
        
        while agentPosition != goalPosition && movesInEpisode < 100 {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms for better visualization
            let action = agent.getBestAction(state: agentPosition)
            let (newPosition, _) = performAction(action)
            agentPosition = newPosition
            movesInEpisode += 1
        }
        
        isDemoing = false
    }
    
    private func generateBestPath() {
        var path: [Position] = [startPosition]
        var currentPos = startPosition
        var visited = Set<Position>()
        
        while currentPos != goalPosition && path.count < 100 {
            visited.insert(currentPos)
            let bestAction = agent.getBestAction(state: currentPos)
            let (newPos, _) = performAction(bestAction, from: currentPos)
            
            if visited.contains(newPos) {
                break // Avoid loops
            }
            
            path.append(newPos)
            currentPos = newPos
        }
        
        bestPath = path
    }
    
    private func performAction(_ action: Action, from position: Position) -> (Position, Double) {
        let delta = action.delta()
        let newX = position.x + delta.dx
        let newY = position.y + delta.dy
        
        if newY >= 0 && newY < gridSize && newX >= 0 && newX < gridSize {
            let newPosition = Position(x: newX, y: newY)
            if maze[newY][newX] != .wall {
                return (newPosition, 0)
            }
        }
        return (position, 0)
    }
}

// MARK: - Main App View
struct ContentView: View {
    @StateObject private var viewModel = MazeViewModel()
    @State private var selection: RLSidebarItem? = .maze
    
    var body: some View {
        NavigationSplitView {
            // Sidebar (Left)
            RLSidebarView(selection: $selection)
        } detail: {
            // Main Content
            if selection == .maze {
                RLMazeContentView(viewModel: viewModel)
                    .inspector(isPresented: .constant(true)) {
                        RLInspectorView(vm: viewModel)
                    }
            }
        }
    }
}

// MARK: - Sidebar Items
enum RLSidebarItem: String, CaseIterable, Identifiable {
    case maze = "RL Labyrinth"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .maze: return "grid"
        }
    }
}

// MARK: - Sidebar View
struct RLSidebarView: View {
    @Binding var selection: RLSidebarItem?
    
    var body: some View {
        List(RLSidebarItem.allCases, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.icon)
        }
        .navigationTitle("KI Labor")
        .listStyle(.sidebar)
    }
}

// MARK: - Main Maze Content View
struct RLMazeContentView: View {
    @ObservedObject var viewModel: MazeViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reinforcement Learning")
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                    
                    Text("Q-Learning Labyrinth-Navigator")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Training mode picker
                Picker("Trainingsmodus", selection: $viewModel.trainingMode) {
                    ForEach(RLTrainingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .disabled(viewModel.isTraining || viewModel.isStepMode)
                
                // Step-by-step info (only in step mode) - MOVED ABOVE MAZE
                if viewModel.isStepMode {
                    RLStepInfoView(
                        currentPhase: viewModel.currentPhase,
                        currentAction: viewModel.currentAction,
                        currentReward: viewModel.currentReward,
                        lastQValue: viewModel.lastQValue,
                        newQValue: viewModel.newQValue
                    )
                    .padding(.horizontal)
                }
                
                // Maze
                MazeGridView(viewModel: viewModel)
                    .aspectRatio(1.0, contentMode: .fit)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(white: 0.97))
                            
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                .padding(1)
                        }
                    )
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.12), radius: 25, x: 0, y: 12)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                
                // Success Rate Chart
                if !viewModel.episodeRewards.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Belohnungsverlauf")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle().fill(.blue).frame(width: 8, height: 8)
                                Text("Belohnungen").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        RLRewardSparkline(values: viewModel.episodeRewards)
                    }
                    .padding(.horizontal)
                }
                
                // Legend
                RLLegendSection()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.trainingMode == .continuous {
                    // Continuous mode buttons
                    if viewModel.isTraining {
                        Button {
                            viewModel.stopTraining()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                        }
                        .tint(.red)
                    } else {
                        Button {
                            viewModel.startTraining()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text("Trainieren")
                            }
                        }
                        .tint(.blue)
                        
                        Button {
                            Task {
                                await viewModel.demonstrateLearning()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Demo")
                            }
                        }
                        .tint(.green)
                        .disabled(viewModel.episode == 0)
                        
                        Button {
                            viewModel.reset()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .tint(.gray)
                    }
                } else {
                    // Step-by-step mode buttons
                    if viewModel.isStepMode {
                        Button {
                            viewModel.stopStepMode()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                Text("Zurücksetzen")
                            }
                        }
                        .tint(.red)
                        
                        Button {
                            viewModel.nextStep()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right")
                                Text("Weiter")
                            }
                        }
                        .tint(.blue)
                    } else {
                        Button {
                            viewModel.startStepMode()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text("Starten")
                            }
                        }
                        .tint(.blue)
                    }
                }
            }
        }
    }
}

// MARK: - Phase Indicator
struct RLPhaseIndicatorView: View {
    let episode: Int
    let successRate: Double
    let explorationRate: Double
    let isTraining: Bool
    let currentPhase: RLTrainingPhase
    let isStepMode: Bool
    let trainingMode: RLTrainingMode
    
    var phaseDescription: String {
        if isStepMode {
            return currentPhase.description
        } else if !isTraining {
            return "Bereit zu starten"
        } else if explorationRate > 0.5 {
            return "Labyrinth erkunden (zufällige Züge)"
        } else if explorationRate > 0.1 {
            return "Optimalen Pfad lernen"
        } else {
            return "Gelerntes Wissen nutzen"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Trainingsstatus")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(phaseDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                // Stats grid
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Episode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(episode)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Erfolgsrate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(successRate, format: .percent.precision(.fractionLength(1)))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(successRate > 0.5 ? .green : .orange)
                            .monospacedDigit()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Erkundung")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(explorationRate, format: .percent.precision(.fractionLength(1)))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                            .monospacedDigit()
                    }
                    
                    Spacer()
                    
                    if isTraining {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
        }
        .padding()
        .background(Color(white: 0.98))
        .cornerRadius(12)
    }
}

// MARK: - Step Info View
struct RLStepInfoView: View {
    let currentPhase: RLTrainingPhase
    let currentAction: Action?
    let currentReward: Double
    let lastQValue: Double
    let newQValue: Double
    
    var actionDetails: (name: String, symbol: String, color: Color) {
        guard let action = currentAction else {
            return ("-", "circle", .gray)
        }
        switch action {
        case .up: return ("Hoch", "arrow.up.circle.fill", .blue)
        case .down: return ("Runter", "arrow.down.circle.fill", .blue)
        case .left: return ("Links", "arrow.left.circle.fill", .blue)
        case .right: return ("Rechts", "arrow.right.circle.fill", .blue)
        }
    }
    
    var phaseExplanation: String {
        switch currentPhase {
        case .idle:
            return "Bereit, nächste Aktion zu wählen"
        case .makingMove:
            return "Agent bewegt sich \(actionDetails.name.lowercased()). Beobachte den Ball!"
        case .calculatingReward:
            return "Zug ausgeführt. Belohnung: \(currentReward > 0 ? "✓ Gut" : "✗ Schlecht") (\(String(format: "%.1f", currentReward)))"
        case .updatingQTable:
            return "Q-Wert aktualisiert von \(String(format: "%.2f", lastQValue)) → \(String(format: "%.2f", newQValue))"
        case .completed:
            return "Training abgeschlossen"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Phase explanation
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text(phaseExplanation)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Stats grid
            HStack(spacing: 12) {
                // Action
                VStack(spacing: 6) {
                    Image(systemName: actionDetails.symbol)
                        .font(.system(size: 32))
                        .foregroundColor(actionDetails.color)
                    Text("Aktion")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(actionDetails.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
                
                // Reward
                VStack(spacing: 6) {
                    Image(systemName: currentReward > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(currentReward > 0 ? .green : .red)
                    Text("Belohnung")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", currentReward))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                // Old Q-value
                VStack(spacing: 6) {
                    Text("Alter Q")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", lastQValue))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.purple)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                // New Q-value
                VStack(spacing: 6) {
                    Text("Neuer Q")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", newQValue))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(white: 0.98))
        .cornerRadius(12)
    }
}

struct RLStepDetailCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - Reward Sparkline
struct RLRewardSparkline: View {
    let values: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = values.max() ?? 1
            let minValue = values.min() ?? -1
            let range = maxValue - minValue
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(max(values.count - 1, 1))
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.98))
                
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height / 2))
                    path.addLine(to: CGPoint(x: width, y: height / 2))
                }
                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                Path { path in
                    for (index, value) in values.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedY = range > 0 ? CGFloat((value - minValue) / range) : 0.5
                        let y = height - (normalizedY * height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
            }
            .cornerRadius(8)
        }
        .frame(height: 80)
    }
}

// MARK: - Legend Section
struct RLLegendSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Legende")
                .font(.headline)
            
            HStack(spacing: 24) {
                RLLegendItem(icon: "figure.walk", color: .green, text: "Start")
                RLLegendItem(icon: "flag.fill", color: .red, text: "Ziel")
                RLLegendItem(icon: "square.fill", color: .black, text: "Wand")
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Agent-Status (Schritt für Schritt)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 20) {
                    RLLegendItem(icon: "circle.fill", color: .blue, text: "Normal")
                    RLLegendItem(icon: "circle.fill", color: .orange, text: "Gültiger Zug")
                    RLLegendItem(icon: "circle.fill", color: .red, text: "Wand")
                    RLLegendItem(icon: "circle.fill", color: .green, text: "Ziel!")
                }
            }
        }
        .padding()
        .background(Color(white: 0.98))
        .cornerRadius(12)
    }
}

struct RLLegendItem: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.caption)
        }
    }
}

// MARK: - Inspector View
struct RLInspectorView: View {
    @ObservedObject var vm: MazeViewModel
    
    var speedLabel: String {
        switch vm.trainingSpeed {
        case .instant: return "Sofort (~3s)"
        case .fast: return "Schnell (~30s)"
        case .medium: return "Mittel (~60s)"
        case .slow: return "Langsam (~120s)"
        }
    }
    
    var phaseDescription: String {
        if vm.isStepMode {
            return vm.currentPhase.description
        } else if !vm.isTraining && !vm.isDemoing {
            return "Bereit zu starten"
        } else if vm.isDemoing {
            return "Gelernter Pfad wird demonstriert"
        } else if vm.explorationRate > 0.5 {
            return "Zufällig erkunden"
        } else if vm.explorationRate > 0.1 {
            return "Muster lernen"
        } else {
            return "Gelerntes Wissen nutzen"
        }
    }
    
    // Convert speed enum to slider value (0-3)
    var speedSliderValue: Double {
        switch vm.trainingSpeed {
        case .slow: return 0
        case .medium: return 1
        case .fast: return 2
        case .instant: return 3
        }
    }
    
    func speedFromSlider(_ value: Double) -> MazeViewModel.RLTrainingSpeed {
        let rounded = Int(value.rounded())
        switch rounded {
        case 0: return .slow
        case 1: return .medium
        case 2: return .fast
        case 3: return .instant
        default: return .medium
        }
    }
    
    var body: some View {
        Form {
            Section("Trainingsmodus") {
                Picker("Modus", selection: $vm.trainingMode) {
                    ForEach(RLTrainingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .disabled(vm.isTraining || vm.isStepMode)
            }
            
            if vm.trainingMode == .continuous {
                Section("Trainingsgeschwindigkeit") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Geschwindigkeit")
                                .font(.subheadline)
                            Spacer()
                            Text(vm.trainingSpeed.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { speedSliderValue },
                                set: { vm.trainingSpeed = speedFromSlider($0) }
                            ),
                            in: 0...3,
                            step: 1
                        )
                        
                        Text(speedLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section("Leistung") {
                LabeledContent("Episode") {
                    Text("\(vm.episode)").monospaced()
                }
                
                LabeledContent("Erfolgsrate") {
                    Text(vm.successRate, format: .percent.precision(.fractionLength(1))).monospaced()
                        .foregroundStyle(vm.successRate > 0.5 ? .green : .orange)
                }
                
                LabeledContent("Schritte") {
                    Text("\(vm.movesInEpisode)").monospaced()
                }
                
                LabeledContent("Erkundungsrate") {
                    HStack(spacing: 4) {
                        Text(vm.explorationRate, format: .percent.precision(.fractionLength(1))).monospaced()
                            .foregroundStyle(.blue)
                        if vm.episode == 0 {
                            Text("(startet bei 100%)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if vm.isStepMode || vm.isTraining || vm.isDemoing {
                    LabeledContent("Aktuelle Phase") {
                        Text(phaseDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Labyrinth-Info") {
                LabeledContent("Größe") {
                    Text("10×10 Gitter").monospaced()
                }
                
                LabeledContent("Startposition") {
                    Text("(1, 1)").monospaced()
                        .foregroundStyle(.green)
                }
                
                LabeledContent("Zielposition") {
                    Text("(10, 10)").monospaced()
                        .foregroundStyle(.red)
                }
                
                Text("Der Agent lernt, vom Start zum Ziel zu navigieren, indem er Belohnungen nutzt.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

struct MazeGridView: View {
    @ObservedObject var viewModel: MazeViewModel
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(geometry.size.width, geometry.size.height) / CGFloat(viewModel.maze.count)
            
            VStack(spacing: 1) {
                ForEach(0..<viewModel.maze.count, id: \.self) { y in
                    HStack(spacing: 1) {
                        ForEach(0..<viewModel.maze[y].count, id: \.self) { x in
                            let position = Position(x: x, y: y)
                            CellView(
                                cellType: viewModel.getCellType(x: x, y: y),
                                isOnPath: viewModel.showPath && viewModel.bestPath.contains(position),
                                explorationRate: viewModel.explorationRate,
                                isActive: viewModel.isTraining || viewModel.isDemoing || viewModel.isStepMode,
                                isAtStart: viewModel.agentPosition.x == 0 && viewModel.agentPosition.y == 0,
                                isAttemptedPosition: viewModel.attemptedPosition == position,
                                isRewardPosition: viewModel.showRewardAnimation && viewModel.rewardPosition == position,
                                rewardValue: viewModel.currentReward,
                                currentPhase: viewModel.currentPhase,
                                currentAction: viewModel.currentAction,
                                agentPosition: viewModel.agentPosition,
                                isAnimatingIntention: viewModel.isAnimatingIntention,
                                isAnimatingResult: viewModel.isAnimatingResult
                            )
                            .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }
}

struct CellView: View {
    let cellType: CellType
    let isOnPath: Bool
    let explorationRate: Double
    let isActive: Bool
    let isAtStart: Bool
    let isAttemptedPosition: Bool
    let isRewardPosition: Bool
    let rewardValue: Double
    let currentPhase: RLTrainingPhase
    let currentAction: Action?
    let agentPosition: Position
    let isAnimatingIntention: Bool
    let isAnimatingResult: Bool
    
    // Calculate offset for ball movement based on action
    var intentionOffset: CGSize {
        guard let action = currentAction else { return .zero }
        let distance: CGFloat = 15 // How far to move back and forth
        let progress = sin(intentionAnimationValue * .pi * 2) // Oscillate -1 to 1
        
        switch action {
        case .up: return CGSize(width: 0, height: progress * distance)
        case .down: return CGSize(width: 0, height: -progress * distance)
        case .left: return CGSize(width: progress * distance, height: 0)
        case .right: return CGSize(width: -progress * distance, height: 0)
        }
    }
    
    // Shake offset for wrong moves
    var shakeOffset: CGSize {
        let shakeAmount: CGFloat = 8
        let progress = sin(shakeAnimationValue * .pi * 8) // Fast shake
        return CGSize(width: progress * shakeAmount, height: 0)
    }
    
    // Slide offset for correct moves
    var slideOffset: CGSize {
        guard let action = currentAction else { return .zero }
        let distance: CGFloat = 20
        let progress = slideAnimationValue // 0 to 1
        
        switch action {
        case .up: return CGSize(width: 0, height: -progress * distance)
        case .down: return CGSize(width: 0, height: progress * distance)
        case .left: return CGSize(width: -progress * distance, height: 0)
        case .right: return CGSize(width: progress * distance, height: 0)
        }
    }
    
    var body: some View {
        ZStack {
            // Background with subtle depth
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
                .shadow(color: shadowColor, radius: cellType == .wall ? 0 : 1, x: 0, y: 1)
            
            // Border
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(borderColor, lineWidth: borderWidth)
            
            
            // ACTUAL AGENT - The real position with animations
            if cellType == .agent && (isActive || isAtStart) {
                ZStack {
                    // Agent ball with dynamic color
                    Circle()
                        .fill(agentColor)
                        .padding(8)
                        .shadow(color: agentColor.opacity(0.4), radius: 3)
                    
                    // Directional arrow inside the ball
                    if let action = currentAction, isAnimatingIntention {
                        Image(systemName: directionArrowSymbol(for: action))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(agentScale)
                .offset(currentOffset)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: agentScale)
                .onAppear {
                    agentScale = 1.08
                    startAnimations()
                }
                .onChange(of: isAnimatingIntention) { _, newValue in
                    if newValue {
                        startIntentionAnimation()
                    }
                }
                .onChange(of: isAnimatingResult) { _, newValue in
                    if newValue {
                        startResultAnimation()
                    }
                }
            }
            
            // Start marker
            if cellType == .start && cellType != .agent {
                Image(systemName: "figure.walk")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 2)
            }
            
            // Goal marker
            if cellType == .goal && cellType != .agent {
                Image(systemName: "flag.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.red)
                    .scaleEffect(goalScale)
                    .shadow(color: .red.opacity(0.3), radius: 2)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: goalScale)
                    .onAppear { goalScale = 1.15 }
            }
        }
    }
    
    @State private var agentScale: CGFloat = 1.0
    @State private var goalScale: CGFloat = 1.0
    @State private var rewardScale: CGFloat = 1.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var intentionAnimationValue: CGFloat = 0
    @State private var shakeAnimationValue: CGFloat = 0
    @State private var slideAnimationValue: CGFloat = 0
    
    private var currentOffset: CGSize {
        if isAnimatingIntention && currentPhase == .makingMove {
            return intentionOffset
        } else if isAnimatingResult && currentPhase == .calculatingReward {
            if rewardValue < 0 {
                return shakeOffset // Shake for wrong
            } else {
                return slideOffset // Slide for correct
            }
        }
        return .zero
    }
    
    private func startAnimations() {
        // Continuous subtle pulse for idle state
    }
    
    private func startIntentionAnimation() {
        intentionAnimationValue = 0
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            intentionAnimationValue = 1
        }
    }
    
    private func startResultAnimation() {
        if rewardValue < 0 {
            // Shake animation for wrong move
            shakeAnimationValue = 0
            withAnimation(.linear(duration: 0.5)) {
                shakeAnimationValue = 1
            }
        } else {
            // Slide animation for correct move
            slideAnimationValue = 0
            withAnimation(.easeOut(duration: 0.5)) {
                slideAnimationValue = 1
            }
        }
    }
    
    private func directionArrowSymbol(for action: Action) -> String {
        switch action {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }
    
    private var agentColor: Color {
        // In step mode, color changes based on reward result
        if isAnimatingResult && currentPhase == .calculatingReward {
            if rewardValue < -0.1 {
                return .red  // Bad reward (hit wall)
            } else if rewardValue > 0 {
                return .green  // Good reward (reached goal)
            } else {
                return .orange  // Small penalty (valid move)
            }
        }
        
        // Default color is blue
        return .blue
    }
    
    private var backgroundColor: Color {
        switch cellType {
        case .empty:
            return Color.white
        case .wall:
            return Color(white: 0.15)
        case .start:
            return Color.green.opacity(0.08)
        case .goal:
            return Color.red.opacity(0.08)
        case .agent:
            return Color.white
        }
    }
    
    private var borderColor: Color {
        switch cellType {
        case .wall:
            return Color(white: 0.1)
        case .start:
            return Color.green.opacity(0.2)
        case .goal:
            return Color.red.opacity(0.2)
        default:
            return Color.black.opacity(0.06)
        }
    }
    
    private var borderWidth: CGFloat {
        switch cellType {
        case .wall:
            return 0.5
        case .start, .goal:
            return 1.5
        default:
            return 0.5
        }
    }
    
    private var shadowColor: Color {
        switch cellType {
        case .wall:
            return .clear
        case .start:
            return Color.green.opacity(0.1)
        case .goal:
            return Color.red.opacity(0.1)
        default:
            return Color.black.opacity(0.03)
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct RewardChartView: View {
    let rewards: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            let maxReward = rewards.max() ?? 1
            let minReward = rewards.min() ?? -1
            let range = maxReward - minReward
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(max(rewards.count - 1, 1))
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.98))
                
                // Grid line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height / 2))
                    path.addLine(to: CGPoint(x: width, y: height / 2))
                }
                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                // Reward line
                Path { path in
                    for (index, reward) in rewards.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedY = range > 0 ? CGFloat((reward - minReward) / range) : 0.5
                        let y = height - (normalizedY * height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
            }
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
