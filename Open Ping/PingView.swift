//
//  DetailView.swift
//  Open Ping
//
//  Created by Merlos on 12/25/24.
//


import SwiftUI

struct PingView: View {
    @Environment(\.dismiss) private var dismiss
    let domainOrIP: String
    @State private var output: String = ""
    @State private var isPinging: Bool = true
    @State private var pinger: SwiftyPing?
    @State private var showSettings = false
    @ObservedObject private var settings = SettingsManager.shared

    init(domainOrIP: String, isPinging: Bool=true) {
        self.domainOrIP = domainOrIP
        self.isPinging = isPinging
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Output Text
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(output)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .font(.system(.caption2, design: .monospaced)) // Monospace font
                            .id("outputText")
                    }
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding()
                    .onChange(of: output) { oldValue, newValue in
                        proxy.scrollTo("outputText", anchor: .bottom)
                    }
                }
                // Start/Stop Button
                HStack(spacing: 12) {
                    if !isPinging {
                        Button(action: { dismiss() }) {
                            Text("⭠ Back")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .frame(width: (geometry.size.width - 32 - 12) / 3)
                    }
                    
                    Button(action: togglePing) {
                        Text(isPinging ? "Stop" : "Start")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isPinging ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(domainOrIP)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: showSettings) { _, isPresented in
            if !isPresented {
                Task {
                    await setupPinger(resetOutput: false)
                }
            }
        }
        .onAppear {
            Task {
                await setupPinger(resetOutput: true)
            }
        }


        .onDisappear {
            if isPinging {
                stopPing()
            }
        }
    }
    
    func setupPinger(resetOutput: Bool) async {
        if resetOutput {
            self.output = "Resolving \(domainOrIP) IP address...\n"
        } else {
            // Stop existing pinger if any
            if let existingPinger = pinger {
                existingPinger.haltPinging()
            }
        }
        
        do {
            let newPinger = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        var config = PingConfiguration(
                            interval: settings.intervalSeconds,
                            with: settings.timeoutSeconds
                        )
                        config.timeToLive = settings.ttl
                        config.payloadSize = settings.packetSize
                        
                        let pinger = try SwiftyPing(
                            host: domainOrIP,
                            configuration: config,
                            queue: DispatchQueue.global()
                        )
                        continuation.resume(returning: pinger)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            self.pinger = newPinger
            
            if resetOutput {
                self.output = ""
                // Update the UI with the ping initialization message
                if let ip = self.pinger?.destination.ip, ip != domainOrIP {
                    self.output += "PING \(domainOrIP) (\(ip)) sent...\n"
                } else {
                    self.output += "PING \(domainOrIP) sent...\n"
                }
            } else {
                self.output += "\n--- Configuration updated (TTL: \(settings.ttl), Size: \(settings.packetSize), Interval: \(Int(settings.intervalMs))ms, Timeout: \(Int(settings.timeoutMs))ms, Interval: \(Int(settings.intervalMs))ms, Timeout: \(Int(settings.timeoutMs))ms) ---\n"
            }
            print("PingView::setupPinger \(domainOrIP) \(isPinging)")
            
            // Start pinging if already active
            if isPinging {
                startPing()
            }
        } catch let error as PingError {
            // Handle PingError with a descriptive message
            let errorMessage = error.errorDescription()
            self.output += "\(errorMessage)\n"
            print("PingView::setupPinger: PingError:  \(errorMessage)")
        } catch {
            // Handle any other errors
            let unknownErrorMessage = "Unknown error: \(error)"
            self.output += "\(unknownErrorMessage)\n"
            print("PingView::setupPinger: UnknownError:  \(unknownErrorMessage)")
        }
    }
    
    func togglePing() {
        if isPinging {
            stopPing()
        } else {
            startPing()
        }
    }
    
    func responseToText(_ response: PingResponse) -> String {
        
        //64 bytes from mad41s13-in-f3.1e100.net (142.250.200.99): icmp_seq=3 ttl=118 time=3.94 ms
        let durationMs = String(format: "%.1f", response.duration * 1000)
        let bytesWithHeader: Int = response.byteCount ?? 0
        let bytes: String = String(bytesWithHeader)
        let ttl: String = String(response.ipHeader?.timeToLive ?? 0)
        let ipAddress: String = response.ipAddress?.description ?? "<ip>"
        return "\(bytes) bytes from \(ipAddress): icmp_sec: \(String(describing: response.sequenceNumber)) ttl: \(ttl)) time: \(durationMs) ms"
    }
    
    func resultToText(_ pingResult: PingResult) -> String {
        
        let transmitted = pingResult.packetsTransmitted
        let received = pingResult.packetsReceived
        let packetLossPercentage = 100 * (Double(transmitted) - Double(received)) / Double(transmitted)
           
        let packetLoss = String(format: "%.1f", packetLossPercentage)
           
        var result = """
           --- \(domainOrIP) ping statistics ---
           \(transmitted) packets transmitted, \(received) packets received, \(packetLoss)% packet loss
           """
           
           if let roundtrip = pingResult.roundtrip {
               let min = String(format: "%.3f", roundtrip.minimum * 1000) // Convert to milliseconds
               let avg = String(format: "%.3f", roundtrip.average * 1000)
               let max = String(format: "%.3f", roundtrip.maximum * 1000)
               let stddev = String(format: "%.3f", roundtrip.standardDeviation * 1000)
               
               result += """
               
               round-trip min/avg/max/stddev = \(min)/\(avg)/\(max)/\(stddev) ms\n\n
               """
           }
           
           return result
    }
    
    func startPing() {
        isPinging = true
        pinger?.observer = { (response) in
            print("pinger::response response for icmp_sec: \(String(describing: response.sequenceNumber))")
            if let error = response.error {
                if error == PingError.responseTimeout {
                    print(error)
                    self.output.append("Request timeout for icmp_seq: \(String(describing: response.sequenceNumber))\n")
                } else {
                    self.output.append("Error: \(error.errorDescription())\n")
                }
            } else {
                self.output.append("\(responseToText(response))\n")
            }
        }
        try! pinger?.startPinging()
        
    }
    func stopPing() {
        isPinging = false
        pinger?.finished = { (result) in
            print("PingView finished with \(result)")
            self.output += resultToText(result)
        }
        pinger?.stopPinging()
    }
}
    
#Preview {
    PingView(domainOrIP: "google.com")
}
