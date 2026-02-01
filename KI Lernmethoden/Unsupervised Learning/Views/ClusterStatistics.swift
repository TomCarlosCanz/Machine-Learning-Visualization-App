//
//  ClusterStatistics.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 05.01.26.
//
import SwiftUI

struct ClusterStatistics: View {
    @ObservedObject var vm: KMeansVM
    
    var clusterInfo: [(id: Int, count: Int, color: Color)] {
        var info: [(Int, Int, Color)] = []
        for centroid in vm.centroids {
            let count = vm.points.filter { $0.clusterId == centroid.clusterId }.count
            info.append((centroid.clusterId, count, centroid.color))
        }
        return info.sorted { $0.0 < $1.0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cluster Analysis Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .foregroundStyle(.blue)
                    Text("Cluster Verteilung")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                if vm.centroids.isEmpty {
                    Text("Klicke auf 'Start K-Means' um die Clusteranalyse zu beginnen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 10) {
                        ForEach(clusterInfo, id: \.id) { info in
                            HStack(spacing: 12) {
                                // Cluster color indicator
                                Circle()
                                    .fill(info.color)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(radius: 1)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(clusterLabel(for: info.id))
                                        .font(.subheadline)
                                        .bold()
                                    
                                    Text("\(info.count) Punkte")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                // Percentage bar
                                let percentage = Double(info.count) / Double(vm.points.count)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.primary.opacity(0.1))
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(info.color)
                                            .frame(width: geo.size.width * percentage)
                                    }
                                }
                                .frame(width: 80, height: 8)
                                
                                Text("\(Int(percentage * 100))%")
                                    .font(.caption)
                                    .bold()
                                    .monospaced()
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    if vm.hasConverged {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Algorithmus konvergiert - Cluster sind stabil")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .cyan.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
    }
    
    func clusterLabel(for clusterId: Int) -> String {
        guard vm.datasetType == .blobs, vm.hasConverged else {
            return "Cluster \(clusterId + 1)"
        }
        
        // Sort clusters by price (y-axis) to assign labels
        let sortedCentroids = vm.centroids.sorted { $0.y < $1.y }
        let labels = ["💰 Günstige Käufer", "🛍️ Durchschnittliche Käufer", "💎 Luxus-Käufer"]
        
        if let index = sortedCentroids.firstIndex(where: { $0.clusterId == clusterId }),
           index < labels.count {
            return labels[index]
        }
        
        return "Cluster \(clusterId + 1)"
    }
    
    private var totalPoints: Int {
        return vm.points.count
    }
}
