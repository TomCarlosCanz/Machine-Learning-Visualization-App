//
//  ClusterPlot.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 05.01.26.
//
import SwiftUI

struct ClusterPlot: View {
    var points: [ClusterPoint]
    var centroids: [Centroid]
    var phase: ClusteringPhase
    var datasetType: DatasetType
    
    let xRange: ClosedRange<Double> = 0...1
    let yRange: ClosedRange<Double> = 0...1
    
    func mapPoint(_ p: CGPoint, in size: CGSize) -> CGPoint {
        let x = (p.x - xRange.lowerBound) / (xRange.upperBound - xRange.lowerBound)
        let y = (p.y - yRange.lowerBound) / (yRange.upperBound - yRange.lowerBound)
        return .init(x: x*size.width, y: (1-y)*size.height)
    }
    
    var xAxisLabel: String {
        switch datasetType {
        case .blobs:
            return "Anzahl Käufe (pro Jahr)"
        case .random:
            return "X-Wert"
        }
    }
    
    var yAxisLabel: String {
        switch datasetType {
        case .blobs:
            return "Ø Preis (€)"
        case .random:
            return "Y-Wert"
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let padding: CGFloat = 40 // Space for labels
            let plotWidth = w - padding
            let plotHeight = h - padding
            
            ZStack(alignment: .bottomLeading) {
                // Grid background
                Canvas { ctx, size in
                    let adjustedSize = CGSize(width: plotWidth, height: plotHeight)
                    let grid = Path { p in
                        for i in stride(from: 0.0, through: 1.0, by: 0.1) {
                            let x = i * adjustedSize.width
                            p.move(to: .init(x: x, y: 0))
                            p.addLine(to: .init(x: x, y: adjustedSize.height))
                        }
                        for j in stride(from: 0.0, through: 1.0, by: 0.1) {
                            let y = j * adjustedSize.height
                            p.move(to: .init(x: 0, y: y))
                            p.addLine(to: .init(x: adjustedSize.width, y: y))
                        }
                    }
                    ctx.stroke(grid, with: .color(Color.primary.opacity(0.07)), lineWidth: 1)
                }
                .offset(x: padding, y: 0)
                
                // Axes
                Path { path in
                    // X-axis
                    path.move(to: .init(x: padding, y: plotHeight))
                    path.addLine(to: .init(x: w, y: plotHeight))
                    // Y-axis
                    path.move(to: .init(x: padding, y: plotHeight))
                    path.addLine(to: .init(x: padding, y: 0))
                }
                .stroke(Color.primary.opacity(0.3), lineWidth: 1.5)
                
                // X-axis label
                Text(xAxisLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .position(x: w / 2 + padding / 2, y: h - 8)
                
                // Y-axis label
                Text(yAxisLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(-90))
                    .position(x: 12, y: plotHeight / 2)
                
                // X-axis tick labels
                ForEach(0..<6) { i in
                    let value = Double(i) * 20 // 0, 20, 40, 60, 80, 100
                    let xPos = padding + (Double(i) / 5.0) * plotWidth
                    
                    Text("\(Int(value))")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .position(x: xPos, y: plotHeight + 18)
                }
                
                // Y-axis tick labels
                ForEach(0..<6) { i in
                    let value = Double(i) * 20 // 0, 20, 40, 60, 80, 100
                    let yPos = plotHeight - (Double(i) / 5.0) * plotHeight
                    
                    Text("\(Int(value))")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .position(x: padding - 12, y: yPos)
                }
                
                // Draw lines from points to centroids during assignment phase
                if phase == .assignment {
                    ForEach(points) { point in
                        if let centroid = centroids.first(where: { $0.clusterId == point.clusterId }) {
                            let p1 = mapPoint(.init(x: point.x, y: point.y), in: CGSize(width: plotWidth, height: plotHeight))
                            let p2 = mapPoint(.init(x: centroid.x, y: centroid.y), in: CGSize(width: plotWidth, height: plotHeight))
                            
                            Path { path in
                                path.move(to: CGPoint(x: p1.x + padding, y: p1.y))
                                path.addLine(to: CGPoint(x: p2.x + padding, y: p2.y))
                            }
                            .stroke(centroid.color.opacity(0.4), lineWidth: 1.5)
                        }
                    }
                }
                
                // Draw data points
                ForEach(points) { point in
                    let m = mapPoint(.init(x: point.x, y: point.y), in: CGSize(width: plotWidth, height: plotHeight))
                    let color = point.clusterId >= 0 ? clusterColors[point.clusterId % clusterColors.count] : Color.gray
                    let isHighlighted = phase == .assignment
                    
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .opacity(isHighlighted ? 1.0 : 0.7)
                        .scaleEffect(isHighlighted ? 1.1 : 1.0)
                        .position(x: m.x + padding, y: m.y)
                        .shadow(radius: 2, y: 1)
                }
                
                // Draw centroids
                ForEach(centroids) { centroid in
                    let m = mapPoint(.init(x: centroid.x, y: centroid.y), in: CGSize(width: plotWidth, height: plotHeight))
                    let isHighlighted = phase == .update
                    
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .fill(centroid.color.opacity(0.2))
                            .frame(width: 28, height: 28)
                        
                        // Main centroid
                        Circle()
                            .fill(centroid.color)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        // Center dot
                        Circle()
                            .fill(.white)
                            .frame(width: 4, height: 4)
                    }
                    .scaleEffect(isHighlighted ? 1.2 : 1.0)
                    .position(x: m.x + padding, y: m.y)
                    .shadow(color: centroid.color.opacity(0.5), radius: 8, y: 3)
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.primary.opacity(0.06)))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
