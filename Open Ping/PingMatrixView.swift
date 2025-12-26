//
//  PingMatrixView.swift
//  Open Ping
//
//  Created by Merlos on 12/26/24.
//

import SwiftUI
import UIKit

struct PingMatrixView: View {
    var results: [PingResponse]
    var timeout: TimeInterval
    
    // Square size
    let size: CGFloat = 16
    let spacing: CGFloat = 4
    let padding: CGFloat = 8
    //Number of lines
    let lines: CGFloat = 4

    // (16 * 4) + (4 * 3) + 16 (padding) = 92
    private var contentHeight: CGFloat {
        (size * lines) + (spacing * (lines - 1)) + (padding * 2)
    }
    
    // Adaptive columns
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: size, maximum: size), spacing: spacing)]
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: spacing) {
                    // Render actual results
                    ForEach(results.indices, id: \.self) { index in
                        cell(for: results[index])
                            .id(index)
                    }
                    //var rest = 20 - results.count
                    // Render placeholders (non-filled squares)
                    //ForEach(0..<rest) { _ in
                     //   placeholderCell()
                    //}
                }
                .padding(8)
                .onChange(of: results.count) { _, count in
                    if count > 0 {
                        withAnimation {
                            proxy.scrollTo(count - 1, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .frame(height: contentHeight)
        }
    }
    
    func cell(for response: PingResponse) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(color(for: response))
            
            if response.error != nil {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
    }
    
    func color(for response: PingResponse) -> Color {
        if response.error != nil { return .red }
        
        // Calculate ratio of duration to timeout (0.0 to 1.0)
        let ratio = min(max(response.duration / timeout, 0), 1.0)
        
        // Interpolate Hue from 0.33 (Green) to 0.0 (Red)
        // 0.33 * (1 - ratio)
        // Green (low latency) -> Yellow -> Orange -> Red (high latency)
        return Color(hue: 0.33 * (1 - ratio), saturation: 1.0, brightness: 0.9)
    }
    
    func placeholderCell() -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(UIColor.systemGray5)) // Light grey that works in dark/light mode
            .frame(width: size, height: size)
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    PingMatrixView(results: [], timeout: 1.0)
}
