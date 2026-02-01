//
//  MLSidebarItem.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 05.01.26.
//


import SwiftUI

enum MLSidebarItem: String, CaseIterable, Identifiable {
    case supervised = "Supervised Learning"
    case unsupervised = "Unsupervised Learning"
    case reinforcement = "Reinforcement Learning"
    case settings = "Einstellungen"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .supervised: return "chart.xyaxis.line"
        case .unsupervised: return "circle.hexagongrid.fill"
        case .reinforcement: return "brain.filled.head.profile"
        case .settings: return "slider.horizontal.3"
            
        }
    }
    
    var subtitle: String {
        switch self {
        case .supervised: return "Gradient Descent"
        case .unsupervised: return "K-Means Clustering"
        case.reinforcement: return "Deep Q-Networks"
        case .settings: return "Labyrinth"
        }
    }
}


/*
 WHAT THIS CODE DOES:
 Little helper file for storing icons, titles and subtitles.
 */
