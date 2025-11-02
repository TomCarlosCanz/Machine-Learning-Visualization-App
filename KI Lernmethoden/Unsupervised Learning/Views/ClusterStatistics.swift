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
            // Prominent Real-World Application Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "briefcase.circle.fill")
                        .foregroundStyle(.orange)
                    
                    Text("Praxis-Anwendung")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(vm.datasetType.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                
                ScrollView {
                    Text(useCaseExample)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxHeight: 250)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [.orange.opacity(0.3), .pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            
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
                                    Text("Cluster \(info.id + 1)")
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
    
    var useCaseExample: String {
        switch vm.datasetType {
        case .blobs:
            return interpretBlobsCluster()
        case .random:
            return interpretRandomCluster()
        }
    }
    
    private func interpretBlobsCluster() -> String {
        guard !vm.centroids.isEmpty else {
            return "E-Commerce Beispiel: Kunden nach Kaufverhalten gruppieren."
        }
        
        // Only show interpretation after convergence
        guard vm.hasConverged else {
            return "📊 E-Commerce Kundensegmentierung\n\nAnalyse läuft..."
        }
        
        var interpretation = "📊 E-Commerce Kundensegmentierung\n\n"
        
        for (index, info) in clusterInfo.enumerated() {
            let percentage = Double(info.count) / Double(totalPoints) * 100
            let meaning: String
            let emoji: String
            
            switch index {
            case 0:
                meaning = "Budget-Käufer mit niedrigen Ausgaben"
                emoji = "🔴"
            case 1:
                meaning = "Standard-Käufer mit moderatem Kaufverhalten"
                emoji = "🔵"
            case 2:
                meaning = "Premium-Kunden mit hohen Ausgaben"
                emoji = "🟢"
            default:
                meaning = "Weitere Kundengruppe"
                emoji = "⚪️"
            }
            
            interpretation += "\(emoji) \(meaning) (\(Int(percentage))%)\n"
        }
        
        return interpretation
    }
    
    private func interpretRandomCluster() -> String {
        guard !vm.centroids.isEmpty else {
            return "Keine echte Praxis-Anwendung: Zufällige Daten haben keine natürliche Gruppierung."
        }
        
        var interpretation = "🎲 Keine echte Praxis-Anwendung\n\n"
        interpretation += "Diese Daten sind komplett zufällig verteilt - es gibt keine natürliche Gruppierung.\n\n"
        
        for (index, info) in clusterInfo.enumerated() {
            let percentage = Double(info.count) / Double(totalPoints) * 100
            interpretation += "• Cluster \(index + 1): \(Int(percentage))%\n"
        }
        
        let inertiaValue = vm.inertia
        interpretation += "\n📊 Inertia: \(String(format: "%.2f", inertiaValue))\n"
        
        if inertiaValue > 2.5 {
            interpretation += "❌ Sehr hoher Wert - Cluster sind bedeutungslos"
        }
        
        return interpretation
    }
    
    private var totalPoints: Int {
        return vm.points.count
    }
}
