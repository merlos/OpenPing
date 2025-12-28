//
//  PingStatsView.swift
//  Open Ping
//
//  Created by Merlos on 12/27/24.
//

import SwiftUI

struct PingStatsView: View {
    var results: [PingResponse]
    var timeout: TimeInterval = 1.0 // Optional with default
    
    private var receivedCount: Int {
        results.filter { $0.error == nil }.count
    }
    
    private var failedCount: Int {
        results.filter { $0.error != nil }.count
    }
    
    private var totalCount: Int {
        results.count
    }
    
    private var successRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(receivedCount) / Double(totalCount)
    }
    
    private var successfulResults: [PingResponse] {
        results.filter { $0.error == nil }
    }
    
    private var minLatency: Double {
        guard !successfulResults.isEmpty else { return 0 }
        return (successfulResults.map { $0.duration }.min() ?? 0) * 1000
    }
    
    private var maxLatency: Double {
        guard !successfulResults.isEmpty else { return 0 }
        return (successfulResults.map { $0.duration }.max() ?? 0) * 1000
    }
    
    private var avgLatency: Double {
        guard !successfulResults.isEmpty else { return 0 }
        let sum = successfulResults.map { $0.duration }.reduce(0, +)
        return (sum / Double(successfulResults.count)) * 1000
    }
    
    private var stdDevLatency: Double {
        guard successfulResults.count > 1 else { return 0 }
        let mean = avgLatency / 1000
        let squaredDiffs = successfulResults.map { pow($0.duration - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(successfulResults.count)
        return sqrt(variance) * 1000
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Donut Chart
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 10)
                
                // Success ring
                Circle()
                    .trim(from: 0, to: successRate)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: successRate)
                
                // Center text
                VStack(spacing: 2) {
                    Text("\(Int(successRate * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("\(receivedCount)/\(totalCount)")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 70, height: 70)
            
            // Stats Grid
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    StatItem(label: "Min", value: formatMs(minLatency))
                    StatItem(label: "Max", value: formatMs(maxLatency))
                }
                HStack(spacing: 16) {
                    StatItem(label: "Avg", value: formatMs(avgLatency))
                    StatItem(label: "StdDev", value: formatMs(stdDevLatency))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground).opacity(0.3))
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatMs(_ value: Double) -> String {
        if value == 0 { return "-" }
        return String(format: "%.1f ms", value)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .frame(minWidth: 70, alignment: .leading)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        PingStatsView(results: [])
            .padding()
    }
}
