//
//  PingOutputView.swift
//  Open Ping
//
//  Created by Merlos on 12/27/24.
//

import SwiftUI

enum PingEvent {
    case resolving(domain: String)
    case started(domain: String, ip: String?)
    case response(PingResponse)
    case configUpdate(ttl: Int, size: Int, intervalMs: Int, timeoutMs: Int)
    case statistics(PingResult, domain: String)
    case error(String)
}

class PingOutputViewModel: ObservableObject {
    @Published var output: String = ""
    
    func handleEvent(_ event: PingEvent) {
        switch event {
        case .resolving(let domain):
            output += "Resolving \(domain) IP address...\n"
            
        case .started(let domain, let ip):
            if let ip = ip, ip != domain {
                output += "PING \(domain) (\(ip)) sent...\n"
            } else {
                output += "PING \(domain) sent...\n"
            }
            
        case .response(let response):
            if let error = response.error {
                if error == PingError.responseTimeout {
                    output += "Request timeout for icmp_seq: \(response.sequenceNumber)\n"
                } else {
                    output += "Error: \(error.errorDescription())\n"
                }
            } else {
                output += "\(responseToText(response))\n"
            }
            
        case .configUpdate(let ttl, let size, let intervalMs, let timeoutMs):
            output += "\n--- Configuration updated (TTL: \(ttl), Size: \(size), Interval: \(intervalMs)ms, Timeout: \(timeoutMs)ms) ---\n"
            
        case .statistics(let result, let domain):
            output += resultToText(result, domain: domain)
            
        case .error(let message):
            output += "\(message)\n"
        }
    }
    
    func clear() {
        output = ""
    }
    
    private func responseToText(_ response: PingResponse) -> String {
        let durationMs = String(format: "%.1f", response.duration * 1000)
        let bytesWithHeader: Int = response.byteCount ?? 0
        let bytes: String = String(bytesWithHeader)
        let ttl: String = String(response.ipHeader?.timeToLive ?? 0)
        let ipAddress: String = response.ipAddress?.description ?? "<ip>"
        return "\(bytes) bytes from \(ipAddress): icmp_sec: \(response.sequenceNumber) ttl: \(ttl)) time: \(durationMs) ms"
    }
    
    private func resultToText(_ pingResult: PingResult, domain: String) -> String {
        let transmitted = pingResult.packetsTransmitted
        let received = pingResult.packetsReceived
        let packetLossPercentage = 100 * (Double(transmitted) - Double(received)) / Double(transmitted)
        let packetLoss = String(format: "%.1f", packetLossPercentage)
        
        var result = """
        --- \(domain) ping statistics ---
        \(transmitted) packets transmitted, \(received) packets received, \(packetLoss)% packet loss\n
        """
        
        if let roundtrip = pingResult.roundtrip {
            let min = String(format: "%.3f", roundtrip.minimum * 1000)
            let avg = String(format: "%.3f", roundtrip.average * 1000)
            let max = String(format: "%.3f", roundtrip.maximum * 1000)
            let stddev = String(format: "%.3f", roundtrip.standardDeviation * 1000)
            
            result += "round-trip min/avg/max/stddev = \(min)/\(avg)/\(max)/\(stddev) ms\n\n"
        }
        
        return result
    }
}

struct PingOutputView: View {
    @ObservedObject var viewModel: PingOutputViewModel
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(viewModel.output)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .font(.system(size: 14, design: .monospaced))
                    .id("outputText")
            }
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            .padding()
            .onChange(of: viewModel.output) { oldValue, newValue in
                proxy.scrollTo("outputText", anchor: .bottom)
            }
        }
    }
}

#Preview {
    PingOutputView(viewModel: PingOutputViewModel())
}
