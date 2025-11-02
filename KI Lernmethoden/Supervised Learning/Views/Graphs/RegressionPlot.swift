//
//  RegressionPlot.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI

struct RegressionPlot: View {
    var points: [SamplePoint]
    var a: Double
    var b: Double
    var phase: TrainingPhase
    var predictions: [Double]
    var showErrorLines: Bool
    
    let xRange: ClosedRange<Double> = 0...1
    let yRange: ClosedRange<Double> = 0...3.2
    
    func mapPoint(_ p: CGPoint, in size: CGSize) -> CGPoint {
        let x = (p.x - xRange.lowerBound) / (xRange.upperBound - xRange.lowerBound)
        let y = (p.y - yRange.lowerBound) / (yRange.upperBound - yRange.lowerBound)
        return .init(x: x*size.width, y: (1-y)*size.height)
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack(alignment: .bottomLeading) {
                Canvas { ctx, size in
                    let grid = Path { p in
                        for i in stride(from: 0.0, through: 1.0, by: 0.1) {
                            let x = i * size.width
                            p.move(to: .init(x: x, y: 0))
                            p.addLine(to: .init(x: x, y: size.height))
                        }
                        for j in stride(from: 0.0, through: 1.0, by: 0.1) {
                            let y = j * size.height
                            p.move(to: .init(x: 0, y: y))
                            p.addLine(to: .init(x: size.width, y: y))
                        }
                    }
                    ctx.stroke(grid, with: .color(Color.primary.opacity(0.07)), lineWidth: 1)
                }
                
                Path { path in
                    path.move(to: .init(x: 0, y: h))
                    path.addLine(to: .init(x: w, y: h))
                    path.move(to: .init(x: 0, y: h))
                    path.addLine(to: .init(x: 0, y: 0))
                }
                .stroke(Color.primary.opacity(0.3), lineWidth: 1.2)

                // Draw error lines (only in calculatingError phase)
                if showErrorLines && !predictions.isEmpty {
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        let actualPoint = mapPoint(.init(x: point.x, y: point.y), in: geo.size)
                        let predictedPoint = mapPoint(.init(x: point.x, y: predictions[index]), in: geo.size)
                        
                        Path { path in
                            path.move(to: actualPoint)
                            path.addLine(to: predictedPoint)
                        }
                        .stroke(
                            LinearGradient(
                                colors: [.red.opacity(0.6), .red.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                        )
                    }
                }

                // Draw all actual data points
                ForEach(points) { p in
                    let m = mapPoint(.init(x: p.x, y: p.y), in: geo.size)
                    
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 10, height: 10)
                        .position(m)
                        .shadow(radius: 2, y: 1)
                }
                
                // Draw prediction points (only in makingPrediction and calculatingError phases)
                if (phase == .makingPrediction || phase == .calculatingError) && !predictions.isEmpty {
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        let predPoint = mapPoint(.init(x: point.x, y: predictions[index]), in: geo.size)
                        
                        Circle()
                            .fill(
                                phase == .makingPrediction
                                    ? Color.blue.opacity(0.7)
                                    : Color.red.opacity(0.7)
                            )
                            .frame(width: 8, height: 8)
                            .position(predPoint)
                            .shadow(radius: 2, y: 1)
                    }
                }

                // Regression line
                Path { path in
                    let y0 = a*0 + b
                    let y1 = a*1 + b
                    
                    // Clamp to visible range and extend to edges
                    let p0 = mapPoint(.init(x: 0, y: max(yRange.lowerBound, min(yRange.upperBound, y0))), in: geo.size)
                    let p1 = mapPoint(.init(x: 1, y: max(yRange.lowerBound, min(yRange.upperBound, y1))), in: geo.size)
                    
                    path.move(to: p0)
                    path.addLine(to: p1)
                }
                .stroke(
                    LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .shadow(color: .orange.opacity(0.35), radius: 8, y: 3)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.primary.opacity(0.06)))
        }
        .aspectRatio(1.45, contentMode: .fit)
    }
}
