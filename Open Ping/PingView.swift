//
//  DetailView.swift
//  Open Ping
//
//  Created by Merlos on 12/25/24.
//


import SwiftUI

struct PingView: View {
    let domainOrIP: String
    @State private var isPinging: Bool = true
    @State private var pinger: SwiftyPing?
    @State private var showSettings = false
    @State private var hasError = false
    @State private var pingResults: [PingResponse] = []
    @StateObject private var outputViewModel = PingOutputViewModel()
    @ObservedObject private var settings = SettingsManager.shared
    @State private var isMatrixExpanded = false

    init(domainOrIP: String, isPinging: Bool=true) {
        self.domainOrIP = domainOrIP
        self.isPinging = isPinging
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            GeometryReader { geometry in
                let buttonHeight: CGFloat = 66
                let matrixTopPadding: CGFloat = 8
                let outputTopPadding: CGFloat = 8
                let totalPadding = matrixTopPadding + outputTopPadding + buttonHeight
                let availableHeight = geometry.size.height - totalPadding
                
                let matrixCollapsedHeight: CGFloat = 120
                let outputExpandedHeight = availableHeight - matrixCollapsedHeight
                // we reverse heights when expanded
                let matrixExpandedHeight = outputExpandedHeight
                let outputCollapsedHeight: CGFloat = matrixCollapsedHeight
                
                
                VStack(spacing: 0) {
                    PingMatrixView(
                        results: pingResults,
                        timeout: settings.timeoutSeconds,
                        availableHeight: isMatrixExpanded ? matrixExpandedHeight : matrixCollapsedHeight
                    )
                    .frame(height: isMatrixExpanded ? matrixExpandedHeight : matrixCollapsedHeight)
                    .background(Color(UIColor.systemBackground).opacity(0.3))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 8)
                    .padding(.top, matrixTopPadding)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            isMatrixExpanded.toggle()
                        }
                    }
                    
                    PingOutputView(viewModel: outputViewModel)
                        .frame(height: isMatrixExpanded ? outputCollapsedHeight : outputExpandedHeight)
                        .padding(.horizontal, 8)
                        .padding(.top, outputTopPadding)
                    
                    // Start/Stop/Retry Button
                    Button(action: togglePing) {
                        ZStack {
                            // Background layer
                            Group {
                                if hasError {
                                    Color.gray
                                } else if isPinging {
                                    Color.red
                                } else {
                                    LinearGradient(
                                        colors: [.green, .teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                            .frame(height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            // Text layer on top
                            Text(hasError ? "Retry" : (isPinging ? "Stop" : "Start"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
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
    
    func setupPinger(resetOutput: Bool, isRetry: Bool = false) async {
        hasError = false
        if resetOutput {
            outputViewModel.clear()
            outputViewModel.handleEvent(.resolving(domain: domainOrIP))
            self.pingResults = []
        } else {
            if isRetry {
                outputViewModel.handleEvent(.resolving(domain: domainOrIP))
                self.pingResults = []
            }
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
            
            if resetOutput || isRetry {
                outputViewModel.handleEvent(.started(domain: domainOrIP, ip: self.pinger?.destination.ip))
            } else {
                outputViewModel.handleEvent(.configUpdate(ttl: settings.ttl, size: settings.packetSize, intervalMs: Int(settings.intervalMs), timeoutMs: Int(settings.timeoutMs)))
            }
            print("PingView::setupPinger \(domainOrIP) \(isPinging)")
            
            // Start pinging if already active
            if isPinging {
                startPing()
            }
        } catch let error as PingError {
            // Handle PingError with a descriptive message
            let errorMessage = error.errorDescription()
            outputViewModel.handleEvent(.error(errorMessage))
            print("PingView::setupPinger: PingError:  \(errorMessage)")
            hasError = true
            isPinging = false
        } catch {
            // Handle any other errors
            let unknownErrorMessage = "Unknown error: \(error)"
            outputViewModel.handleEvent(.error(unknownErrorMessage))
            print("PingView::setupPinger: UnknownError:  \(unknownErrorMessage)")
            hasError = true
            isPinging = false
        }
    }
    
    func togglePing() {
        if hasError {
            isPinging = true
            Task {
                await setupPinger(resetOutput: false, isRetry: true)
            }
        } else if isPinging {
            stopPing()
        } else {
            startPing()
        }
    }
    
    func startPing() {
        isPinging = true
        pinger?.observer = { (response) in
            // Update results on main thread
            DispatchQueue.main.async {
                self.pingResults.append(response)
            }
            
            print("pinger::response response for icmp_sec: \(String(describing: response.sequenceNumber))")
            self.outputViewModel.handleEvent(.response(response))
        }
        try! pinger?.startPinging()
        
    }
    func stopPing() {
        isPinging = false
        pinger?.finished = { (result) in
            print("PingView finished with \(result)")
            self.outputViewModel.handleEvent(.statistics(result, domain: self.domainOrIP))
        }
        pinger?.stopPinging()
    }
}
    
#Preview {
    PingView(domainOrIP: "google.com")
}
