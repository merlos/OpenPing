//
//  SettingsManager.swift
//  Open Ping
//
//  Created by Merlos on 12/21/25.
//

import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("pingTTL") var ttl: Int = 64
    @AppStorage("pingTimeout") var timeoutMs: Double = 1000 // milliseconds
    @AppStorage("pingInterval") var intervalMs: Double = 1000 // milliseconds
    @AppStorage("pingPacketSize") var packetSize: Int = 56 // bytes
    
    // Protocol boundaries
    let minTTL = 1
    let maxTTL = 255
    
    let minTimeout = 100.0 // 100ms
    let maxTimeout = 10000.0 // 10s
    
    let minInterval = 100.0 // 100ms
    let maxInterval = 10000.0 // 10s
    
    let minPacketSize = 16 // Minimum for UUID fingerprint in SwiftyPing
    let maxPacketSize = 65500 // Max IP packet size approx
    
    var intervalSeconds: TimeInterval {
        return intervalMs / 1000.0
    }
    
    var timeoutSeconds: TimeInterval {
        return timeoutMs / 1000.0
    }
    
    init() {}
    
    func resetToDefaults() {
        ttl = 64
        timeoutMs = 1000
        intervalMs = 1000
        packetSize = 56
    }
}
