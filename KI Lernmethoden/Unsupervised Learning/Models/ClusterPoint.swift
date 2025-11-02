//
//  ClusterPoint.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 05.01.26.
//
import SwiftUI

struct ClusterPoint: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var clusterId: Int = -1 // -1 means unassigned
}

struct Centroid: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let clusterId: Int
    
    var color: Color {
        clusterColors[clusterId % clusterColors.count]
    }
}

let clusterColors: [Color] = [.red, .blue, .green, .purple, .orange, .pink, .cyan, .indigo]

enum ClusteringPhase {
    case idle
    case assignment  // Assigning points to nearest centroid
    case update      // Moving centroids to cluster means
}

enum DatasetType: String, CaseIterable, Identifiable {
    case blobs = "Drei Gruppen"
    case random = "Zufällig verteilt"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .blobs: return "Klar getrennte Cluster"
        case .random: return "Keine klare Struktur"
        }
    }
    
    var realLifeExample: String {
        switch self {
        case .blobs:
            return "Beispiel: Kundensegmente nach Alter & Einkommen - junge Studenten, mittelalte Familien, wohlhabende Senioren"
        case .random:
            return "Beispiel: Völlig zufällige Daten ohne echte Gruppierung - kein sinnvolles Clustering möglich"
        }
    }
}
