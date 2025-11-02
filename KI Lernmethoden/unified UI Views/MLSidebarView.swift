//
//  MLSidebarView.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 05.01.26.
//


import SwiftUI

struct MLSidebarView: View {
    @Binding var selection: MLSidebarItem?
    
    var body: some View {
        List(selection: $selection) {
            Section("Machine Learning") {
                ForEach([MLSidebarItem.supervised, MLSidebarItem.unsupervised]) { item in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.rawValue)
                                .font(.body)
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: item.icon)
                    }
                    .tag(item)
                }
            }
            
            Section {
                Label(MLSidebarItem.settings.rawValue, systemImage: MLSidebarItem.settings.icon)
                    .tag(MLSidebarItem.settings)
            }
        }
        .navigationTitle("KI-Labor")
        .listStyle(.sidebar)
    }
}