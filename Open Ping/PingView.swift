//
//  DetailView.swift
//  Open Ping
//
//  Created by Merlos on 12/25/24.
//


import SwiftUI

struct PingView: View {
    let domainOrIP: String
    @State private var output: String = ""
    @State private var isPinging: Bool = true
    //@State private var pinger: Pinger
    @State private var pinger: SwiftyPing?

    init(domainOrIP: String, isPinging: Bool=true) {
        self.domainOrIP = domainOrIP
        self.isPinging = isPinging
    }
    
    var body: some View {
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
            Button(action: togglePing) {
                Text(isPinging ? "Stop" : "Start")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPinging ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .navigationTitle(domainOrIP)
        .onAppear {
            // setups pinger
            self.pinger = try! SwiftyPing(host: domainOrIP, configuration: PingConfiguration(interval: 0.5, with: 5), queue: DispatchQueue.global())
            print("PingView::OnAppear \(domainOrIP) \(isPinging)")
            if isPinging {
               startPing()
            }
        }
        .onDisappear {
            stopPing()
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
        let bytesWithHeader: Int = response.byteCount ?? 0 + 20
        let bytes: String = String(bytesWithHeader)
        let ttl: String = String(response.ipHeader?.timeToLive ?? 0)
        let ipAddress: String = response.ipAddress?.description ?? "<ip>"
        return "\(bytes) bytes from  \(ipAddress): icmp_sec: \(String(describing: response.sequenceNumber)) ttl: \(ttl)) time: \(durationMs) ms"
    }
    
    func resultToText(_ result: PingResult) -> String {
        return "result"
    }
    
    func startPing() {
        isPinging = true
        pinger?.observer = { (response) in
            let duration = response.duration
                print(duration)
                self.output.append("\(responseToText(response))\n")
            }
        try! pinger?.startPinging()
    }
    func stopPing() {
        isPinging = false
        pinger?.finished = { (result) in
            print("PingView finished with \(result)")
        }
        pinger?.stopPinging()
    }
}
    
#Preview {
    PingView(domainOrIP: "google.com")
}
