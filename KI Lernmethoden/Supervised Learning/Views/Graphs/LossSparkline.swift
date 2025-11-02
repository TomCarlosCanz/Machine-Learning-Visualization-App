//
//  LossSparkline.swift
//  KI Lernmethoden
//
//  Created by Tom Canz on 15.11.25.
//
import SwiftUI

struct LossSparkline: View {
    var values: [Double]
    
    var body: some View {
        GeometryReader { geo in
            let minV = values.min() ?? 0
            let maxV = values.max() ?? 1
            let range = max(maxV - minV, 1e-6)
            
            ZStack {
                // Loss line (orange/pink gradient)
                Path { path in
                    for (i, v) in values.enumerated() {
                        let x = CGFloat(i) / CGFloat(max(values.count-1, 1)) * geo.size.width
                        let y = (1 - CGFloat((v - minV) / range)) * geo.size.height
                        if i == 0 { path.move(to: .init(x: x, y: y)) } else { path.addLine(to: .init(x: x, y: y)) }
                    }
                }
                .stroke(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
            }
        }
        .frame(height: 48)
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
