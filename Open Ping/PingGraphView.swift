//
//  PingGraphView.swift
//  Open Ping
//
//  Created by Merlos on 12/27/24.
//

import SwiftUI

struct PingGraphView: View {
    var results: [PingResponse]
    var timeout: TimeInterval
    
    private var successfulResults: [(index: Int, duration: Double)] {
        results.enumerated().compactMap { index, response in
            response.error == nil ? (index: index, duration: response.duration * 1000) : nil
        }
    }
    
    private var allDurations: [Double?] {
        results.map { $0.error == nil ? $0.duration * 1000 : nil }
    }
    
    private var maxLatency: Double {
        let maxValue = successfulResults.map { $0.duration }.max() ?? 0
        return max(maxValue * 1.1, 1) // +10% or at least 1ms
    }
    
    private var minLatency: Double {
        successfulResults.map { $0.duration }.min() ?? 0
    }
    
    private var avgLatency: Double {
        guard !successfulResults.isEmpty else { return 0 }
        return successfulResults.map { $0.duration }.reduce(0, +) / Double(successfulResults.count)
    }
    
    // Calculate 5-ping moving average
    private func movingAverage(at index: Int) -> Double? {
        let windowSize = 5
        let start = max(0, index - windowSize + 1)
        let window = allDurations[start...index].compactMap { $0 }
        guard !window.isEmpty else { return nil }
        return window.reduce(0, +) / Double(window.count)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let barWidth: CGFloat = 6
            let barSpacing: CGFloat = 2
            let chartHeight = geometry.size.height - 20 // Leave space for labels
            let chartWidth = geometry.size.width - 40 // Leave space for Y axis labels
            
            ZStack(alignment: .topLeading) {
                // Y-axis labels
                VStack {
                    Text(formatMs(maxLatency))
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatMs(maxLatency / 2))
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("0")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .frame(width: 35, height: chartHeight)
                
                // Chart area
                ZStack(alignment: .bottomLeading) {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<3) { _ in
                            Divider()
                                .background(Color.secondary.opacity(0.3))
                            Spacer()
                        }
                    }
                    .frame(height: chartHeight)
                    
                    // Max line
                    if !successfulResults.isEmpty {
                        Rectangle()
                            .fill(Color.red.opacity(0.5))
                            .frame(height: 1)
                            .offset(y: -chartHeight * CGFloat(maxLatency / 1.1 / maxLatency))
                    }
                    
                    // Min line
                    if !successfulResults.isEmpty && minLatency > 0 {
                        Rectangle()
                            .fill(Color.green.opacity(0.5))
                            .frame(height: 1)
                            .offset(y: -chartHeight * CGFloat(minLatency / maxLatency))
                    }
                    
                    // Bars and moving average
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            ZStack(alignment: .bottomLeading) {
                                // Bars
                                HStack(alignment: .bottom, spacing: barSpacing) {
                                    ForEach(results.indices, id: \.self) { index in
                                        if let duration = allDurations[index] {
                                            let barHeight = chartHeight * CGFloat(duration / maxLatency)
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(barGradient(for: duration))
                                                .frame(width: barWidth, height: max(barHeight, 2))
                                        } else {
                                            // Failed ping - show red marker
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.red.opacity(0.7))
                                                .frame(width: barWidth, height: 4)
                                        }
                                    }
                                }
                                .id("bars")
                                
                                // Moving average line
                                Path { path in
                                    var started = false
                                    for index in results.indices {
                                        if let avg = movingAverage(at: index) {
                                            let x = CGFloat(index) * (barWidth + barSpacing) + barWidth / 2
                                            let y = chartHeight - (chartHeight * CGFloat(avg / maxLatency))
                                            
                                            if !started {
                                                path.move(to: CGPoint(x: x, y: y))
                                                started = true
                                            } else {
                                                path.addLine(to: CGPoint(x: x, y: y))
                                            }
                                        }
                                    }
                                }
                                .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            }
                            .frame(height: chartHeight)
                        }
                        .onChange(of: results.count) { _, _ in
                            withAnimation {
                                proxy.scrollTo("bars", anchor: .trailing)
                            }
                        }
                    }
                }
                .offset(x: 40)
                .frame(width: chartWidth, height: chartHeight)
                
                // Legend
                HStack(spacing: 12) {
                    LegendItem(color: .green, label: "Min")
                    LegendItem(color: .red, label: "Max")
                    LegendItem(color: .orange, label: "Avg(5)")
                }
                .font(.system(size: 9))
                .offset(x: 40, y: chartHeight + 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground).opacity(0.3))
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func barGradient(for duration: Double) -> LinearGradient {
        let ratio = min(duration / (timeout * 1000), 1.0)
        let hue = 0.33 * (1 - ratio) // Green to Red
        return LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0.8, brightness: 0.9),
                Color(hue: hue, saturation: 1.0, brightness: 0.7)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func formatMs(_ value: Double) -> String {
        if value < 1 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.0f", value)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        PingGraphView(results: [], timeout: 1.0)
            .frame(height: 150)
            .padding()
    }
}
