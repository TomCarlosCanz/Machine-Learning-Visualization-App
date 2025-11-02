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
    
    let xRange: ClosedRange<Double> = 0...1
    let yRange: ClosedRange<Double> = 0...1
    
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
                // Grid background
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
                
                // Axes
                Path { path in
                    path.move(to: .init(x: 0, y: h))
                    path.addLine(to: .init(x: w, y: h))
                    path.move(to: .init(x: 0, y: h))
                    path.addLine(to: .init(x: 0, y: 0))
                }
                .stroke(Color.primary.opacity(0.3), lineWidth: 1.2)
                
                // Draw lines from points to centroids during assignment phase
                if phase == .assignment {
                    ForEach(points) { point in
                        if let centroid = centroids.first(where: { $0.clusterId == point.clusterId }) {
                            let p1 = mapPoint(.init(x: point.x, y: point.y), in: geo.size)
                            let p2 = mapPoint(.init(x: centroid.x, y: centroid.y), in: geo.size)
                            
                            Path { path in
                                path.move(to: p1)
                                path.addLine(to: p2)
                            }
                            .stroke(centroid.color.opacity(0.4), lineWidth: 1.5)
                        }
                    }
                }
                
                // Draw data points
                ForEach(points) { point in
                    let m = mapPoint(.init(x: point.x, y: point.y), in: geo.size)
                    let color = point.clusterId >= 0 ? clusterColors[point.clusterId % clusterColors.count] : Color.gray
                    let isHighlighted = phase == .assignment
                    
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .opacity(isHighlighted ? 1.0 : 0.7)
                        .scaleEffect(isHighlighted ? 1.1 : 1.0)
                        .position(m)
                        .shadow(radius: 2, y: 1)
                }
                
                // Draw centroids
                ForEach(centroids) { centroid in
                    let m = mapPoint(.init(x: centroid.x, y: centroid.y), in: geo.size)
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
                    .position(m)
                    .shadow(color: centroid.color.opacity(0.5), radius: 8, y: 3)
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.primary.opacity(0.06)))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
