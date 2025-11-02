//
//  SettingsDetail.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI

struct SettingsDetail: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gearshape")
                .font(.largeTitle)
            Text("Einstellungen & About")
                .font(.title2)
            Text("Dies ist eine iPad-optimierte SwiftUI-Demo für überwachtens Lernen mit Gradient Descent. Der Workflow zeigt deutlich: Training → Testing → Anpassung für jede Epoche.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
