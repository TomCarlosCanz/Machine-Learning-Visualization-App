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
    case settings = "Einstellungen"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .supervised: return "chart.xyaxis.line"
        case .unsupervised: return "circle.hexagongrid.fill"
        case .settings: return "slider.horizontal.3"
        }
    }
    
    var subtitle: String {
        switch self {
        case .supervised: return "Gradient Descent"
        case .unsupervised: return "K-Means Clustering"
        case .settings: return ""
        }
    }
}