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
    var availableHeight: CGFloat
    
    // Square size
    let size: CGFloat = 16
    let spacing: CGFloat = 4
    let padding: CGFloat = 8
    
    // Calculate lines dynamically based on available height
    private var lines: Int {
        let heightForCells = availableHeight - (padding * 2)
        let lineHeight = size + spacing
        return max(4, Int(heightForCells / lineHeight))
    }

    // (16 * 4) + (4 * 3) + 16 (padding) = 92
    private var contentHeight: CGFloat {
        (size * CGFloat(lines)) + (spacing * CGFloat(lines - 1)) + (padding * 2)
    }
    
    // Adaptive columns
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: size, maximum: size), spacing: spacing)]
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (padding * 2)
            let columnsCount = Int((availableWidth + spacing) / (size + spacing))
            let capacity = columnsCount * lines
            let placeholdersCount = max(0, capacity - results.count)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        // Render actual results
                        ForEach(results.indices, id: \.self) { index in
                            cell(for: results[index])
                                .id("result-\(index)")
                        }
                        
                        // Render placeholders (non-filled squares)
                        ForEach(0..<placeholdersCount, id: \.self) { index in
                            placeholderCell()
                                .id("placeholder-\(index)")
                        }
                    }
                    .padding(padding)
                    .onChange(of: results.count) { _, count in
                        if count > 0 {
                            withAnimation {
                                proxy.scrollTo("result-\(count - 1)", anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
            }
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
        
        // Ensure timeout is positive to avoid division by zero
        let safeTimeout = max(timeout, 0.001)
        
        // Calculate ratio of duration to timeout (0.0 to 1.0)
        let ratio = min(max(response.duration / safeTimeout, 0), 1.0)
        
        // Interpolate Hue from 0.33 (Green) to 0.0 (Red)
        // 0.33 * (1 - ratio)
        // Green (low latency) -> Yellow -> Orange -> Red (high latency)
        let hue = 0.33 * (1 - ratio)
        return Color(hue: hue, saturation: 1.0, brightness: 0.9)
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
    PingMatrixView(results: [], timeout: 1.0, availableHeight: 92)
}
