//
//  SettingsView.swift
//  Open Ping
//
//  Created by Merlos on 12/21/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Ping Configuration")) {
                    // TTL
                    VStack(alignment: .leading) {
                        Text("TTL (Time to Live)")
                        Text("Max number of hops (routers) before packet is discarded.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: Binding(
                                get: { Double(settings.ttl) },
                                set: { settings.ttl = Int($0) }
                            ), in: Double(settings.minTTL)...Double(settings.maxTTL), step: 1)
                            
                            TextField("TTL", value: $settings.ttl, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: settings.ttl) { _, newValue in
                                    if newValue < settings.minTTL { settings.ttl = settings.minTTL }
                                    if newValue > settings.maxTTL { settings.ttl = settings.maxTTL }
                                }
                        }
                    }
                    
                    // Timeout
                    VStack(alignment: .leading) {
                        Text("Timeout (ms)")
                        Text("Time to wait for a response (pong).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: $settings.timeoutMs, in: settings.minTimeout...settings.maxTimeout, step: 100)
                            
                            TextField("ms", value: $settings.timeoutMs, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: settings.timeoutMs) { _, newValue in
                                    if newValue < settings.minTimeout { settings.timeoutMs = settings.minTimeout }
                                    if newValue > settings.maxTimeout { settings.timeoutMs = settings.maxTimeout }
                                }
                        }
                    }
                    
                    // Interval
                    VStack(alignment: .leading) {
                        Text("Send Interval (ms)")
                        Text("Time between sending ping packets.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: $settings.intervalMs, in: settings.minInterval...settings.maxInterval, step: 100)
                            
                            TextField("ms", value: $settings.intervalMs, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: settings.intervalMs) { _, newValue in
                                    if newValue < settings.minInterval { settings.intervalMs = settings.minInterval }
                                    if newValue > settings.maxInterval { settings.intervalMs = settings.maxInterval }
                                }
                        }
                    }
                    
                    // Packet Size
                    VStack(alignment: .leading) {
                        Text("Packet Size (bytes)")
                        Text("Size of the data payload.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: Binding(
                                get: { Double(settings.packetSize) },
                                set: { settings.packetSize = Int($0) }
                            ), in: Double(settings.minPacketSize)...1500, step: 1) // Slider capped at 1500 for usability, but text can go higher
                            
                            TextField("bytes", value: $settings.packetSize, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: settings.packetSize) { _, newValue in
                                    if newValue < settings.minPacketSize { settings.packetSize = settings.minPacketSize }
                                    if newValue > settings.maxPacketSize { settings.packetSize = settings.maxPacketSize }
                                }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        settings.resetToDefaults()
                    }) {
                        Text("Reset to Defaults")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
