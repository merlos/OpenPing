//
//  PingUtility.swift
//  Open Ping
//
//  Created by Merlos on 12/25/24.
//


import Foundation

struct ICMPPacket {
    var type: UInt8
    var code: UInt8
    var checksum: UInt16
    var identifier: UInt16
    var sequenceNumber: UInt16
}

class Pinger {
    private var socket: Int32 = -1
    private let identifier = UInt16.random(in: 0..<UInt16.max)
    private var sequenceNumber: UInt16 = 0
    private var timeout: TimeInterval = 2.0
    private var host: String = ""
    
    init(host: String, timeout: TimeInterval = 2.0) {
        self.host = host
        self.timeout = timeout
    }
    
    func startPing() {
        print("Pinger::startPing \(host)")
        do {
            socket = try createSocket()
            try performPing()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func stopPing() {
        if socket != -1 {
            close(socket)
            socket = -1
        }
    }
    
    private func createSocket() throws -> Int32 {
        let sock = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
        if sock < 0 {
            throw NSError(domain: "Pinger", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create socket"])
        }
        return sock
    }
    
    private func performPing() throws {
        guard let destination = resolveHostName(host) else {
            throw NSError(domain: "Pinger", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to resolve hostname"])
        }
        
        var icmpPacket = createICMPPacket()
        let packetSize = MemoryLayout.size(ofValue: icmpPacket)
        
        let sendSize = withUnsafePointer(to: &icmpPacket) {
            $0.withMemoryRebound(to: UInt8.self, capacity: packetSize) { packetPointer in
                destination.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                    sendto(socket, packetPointer, packetSize, 0, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
        
        if sendSize < 0 {
            throw NSError(domain: "Pinger", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unable to send ICMP packet"])
        }
        print("Ping sent to \(host)")
        try readResponse()
    }


    private func resolveHostName(_ hostName: String) -> UnsafePointer<sockaddr_in>? {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_DGRAM
        
        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(hostName, nil, &hints, &result)
        if status != 0 {
            return nil
        }
        
        defer {
            freeaddrinfo(result)
        }
        
        guard let addr = result?.pointee.ai_addr else {
            return nil
        }
        
        return UnsafeRawPointer(addr).bindMemory(to: sockaddr_in.self, capacity: 1)
    }
    
    private func createICMPPacket() -> ICMPPacket {
        sequenceNumber += 1
        var packet = ICMPPacket(type: 8, code: 0, checksum: 0, identifier: identifier, sequenceNumber: sequenceNumber)
        packet.checksum = calculateChecksum(&packet, size: MemoryLayout.size(ofValue: packet))
        return packet
    }
    
    private func calculateChecksum(_ buffer: UnsafeRawPointer, size: Int) -> UInt16 {
        let buf = buffer.bindMemory(to: UInt16.self, capacity: size / 2)
        var checksum: UInt32 = 0
        for i in 0..<size / 2 {
            checksum += UInt32(buf[i])
        }
        while (checksum >> 16) != 0 {
            checksum = (checksum & 0xFFFF) + (checksum >> 16)
        }
        return ~UInt16(checksum & 0xFFFF)
    }
    
    private func readResponse() throws {
        var responseBuffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = recv(socket, &responseBuffer, responseBuffer.count, 0)
        
        if bytesRead < 0 {
            throw NSError(domain: "Pinger", code: -4, userInfo: [NSLocalizedDescriptionKey: "Error reading response"])
        }
        
        print("Received response: \(responseBuffer.prefix(bytesRead))")
    }
}

