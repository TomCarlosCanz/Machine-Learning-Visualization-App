//
//  RegressionPlot.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI

struct RegressionPlot: View {
    
    //VARIABLES
    var points: [SamplePoint]
    var a: Double
    var b: Double
    var phase: TrainingPhase
    var predictions: [Double]
    var showErrorLines: Bool
    
    // Scenario for value formatting
    var scenario: Scenario
    
    let xRange: ClosedRange<Double> = 0...1
    let yRange: ClosedRange<Double> = 0...3.5
    
    //figures out where to place points: stretches them to fit the views size, flips them so that bigger values are higher up
    func mapPoint(_ p: CGPoint, in size: CGSize) -> CGPoint {
        let x = (p.x - xRange.lowerBound) / (xRange.upperBound - xRange.lowerBound)
        let y = (p.y - yRange.lowerBound) / (yRange.upperBound - yRange.lowerBound)
        return .init(x: x*size.width, y: (1-y)*size.height)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Y-axis values
                yAxisValues
                    .frame(width: 75)
                
                // Main plot area
                plotContent
                
                // Y-axis label (vertical, on the right side)
                Text(scenario.yAxisLabel)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 80)
                    .fixedSize()
            }
            
            HStack(spacing: 8) {
                Spacer()
                    .frame(width: 75) // Align with y-axis values
                
                // X-axis values
                xAxisValues
                    .frame(height: 25)
                
                Spacer()
                    .frame(width: 80) // Align with y-axis label
            }
            
            // X-axis label (centered below everything)
            Text(scenario.xAxisLabel)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
        }
    }
    
    // Y-axis values (vertical) - using real-world values
    var yAxisValues: some View {
        GeometryReader { geo in
            ZStack(alignment: .trailing) {
                ForEach(0..<6) { i in
                    let normalizedValue = yRange.upperBound - (Double(i) * (yRange.upperBound - yRange.lowerBound) / 5)
                    let yPos = CGFloat(i) / 5 * geo.size.height
                    
                    Text(scenario.yLabel(normalizedValue))
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.primary)
                        .position(x: geo.size.width - 10, y: yPos)
                }
            }
        }
    }
    
    // X-axis values (horizontal) - using real-world values
    var xAxisValues: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                ForEach(0..<6) { i in
                    let normalizedValue = xRange.lowerBound + (Double(i) * (xRange.upperBound - xRange.lowerBound) / 5)
                    let xPos = CGFloat(i) / 5 * geo.size.width
                    
                    Text(scenario.xLabel(normalizedValue))
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.primary)
                        .position(x: xPos, y: geo.size.height / 2)
                }
            }
        }
    }
    
    // Original plot content
    var plotContent: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let padding: CGFloat = 18 // Increased padding to keep content within axes
            
            ZStack(alignment: .bottomLeading) {
                
                // Background and border for entire plot area
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .cornerRadius(22)
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.primary.opacity(0.06)))
                
                //Uses canvas as it is efficient to draw
                Canvas { ctx, size in
                    let grid = Path { p in
                        for i in stride(from: 0.0, through: 1.0, by: 0.1) {
                            let x = i * (size.width - padding * 2) + padding
                            p.move(to: .init(x: x, y: padding))
                            p.addLine(to: .init(x: x, y: size.height - padding))
                        }
                        for j in stride(from: 0.0, through: 1.0, by: 0.1) {
                            let y = j * (size.height - padding * 2) + padding
                            p.move(to: .init(x: padding, y: y))
                            p.addLine(to: .init(x: size.width - padding, y: y))
                        }
                    }
                    ctx.stroke(grid, with: .color(Color.primary.opacity(0.07)), lineWidth: 1)
                }
                
                //same path as in loss sparkline
                Path { path in
                    path.move(to: .init(x: padding, y: h - padding))
                    path.addLine(to: .init(x: w - padding, y: h - padding))
                    path.move(to: .init(x: padding, y: h - padding))
                    path.addLine(to: .init(x: padding, y: padding))
                }
                .stroke(Color.primary.opacity(0.3), lineWidth: 1.2)
                
                
                //Shows red dashed lines to show how far the assumption/prediction of the model was of
                Group {
                    if showErrorLines && !predictions.isEmpty {
                        ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                            let actualPoint = mapPoint(.init(x: point.x, y: point.y), in: CGSize(width: w - padding * 2, height: h - padding * 2))
                            let predictedPoint = mapPoint(.init(x: point.x, y: predictions[index]), in: CGSize(width: w - padding * 2, height: h - padding * 2))
                            
                            Path { path in
                                path.move(to: CGPoint(x: actualPoint.x + padding, y: actualPoint.y + padding))
                                path.addLine(to: CGPoint(x: predictedPoint.x + padding, y: predictedPoint.y + padding))
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
                        let m = mapPoint(.init(x: p.x, y: p.y), in: CGSize(width: w - padding * 2, height: h - padding * 2))
                        
                        Circle()
                            .fill(LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 10, height: 10)
                            .position(x: m.x + padding, y: m.y + padding)
                            .shadow(radius: 2, y: 1)
                    }
                    
                    // Draw prediction points
                    if (phase == .makingPrediction || phase == .calculatingError) && !predictions.isEmpty {
                        ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                            let predPoint = mapPoint(.init(x: point.x, y: predictions[index]), in: CGSize(width: w - padding * 2, height: h - padding * 2))
                            
                            Circle()
                                .fill(
                                    phase == .makingPrediction
                                        ? Color.blue.opacity(0.7)
                                        : Color.red.opacity(0.7)
                                )
                                .frame(width: 8, height: 8)
                                .position(x: predPoint.x + padding, y: predPoint.y + padding)
                                .shadow(radius: 2, y: 1)
                        }
                    }

                    // Regression line
                    Path { path in
                        let y0 = a*0 + b
                        let y1 = a*1 + b
                        
                        let p0 = mapPoint(.init(x: 0, y: max(yRange.lowerBound, min(yRange.upperBound, y0))), in: CGSize(width: w - padding * 2, height: h - padding * 2))
                        let p1 = mapPoint(.init(x: 1, y: max(yRange.lowerBound, min(yRange.upperBound, y1))), in: CGSize(width: w - padding * 2, height: h - padding * 2))
                        
                        path.move(to: CGPoint(x: p0.x + padding, y: p0.y + padding))
                        path.addLine(to: CGPoint(x: p1.x + padding, y: p1.y + padding))
                    }
                    .stroke(
                        LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .shadow(color: .orange.opacity(0.35), radius: 8, y: 3)
                }
            }
        }
        .aspectRatio(1.45, contentMode: .fit)
    }
}
/*
 WHAT THIS CODE DOES
 - shows all necessary graphs and plots
 - mostly just geometry, Paths, Gradients and Canvas
 */
