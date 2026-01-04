//
//  SettingsView.swift
//  Open Ping
//
//  Created by Merlos on 12/21/25.
//

import SwiftUI

// Validated numeric text field that validates on blur
struct ValidatedNumberField: View {
    let placeholder: String
    @Binding var value: Int
    let min: Int
    let max: Int
    let toastDuration: TimeInterval
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    init(_ placeholder: String, value: Binding<Int>, min: Int, max: Int, toastDuration: TimeInterval = 2.0) {
        self.placeholder = placeholder
        self._value = value
        self.min = min
        self.max = max
        self.toastDuration = toastDuration
        self._textValue = State(initialValue: String(value.wrappedValue))
    }
    
    var body: some View {
        TextField(placeholder, text: $textValue)
            .keyboardType(.numberPad)
            .frame(width: 70)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focused($isFocused)
            .onChange(of: textValue) { _, newValue in
                // Only allow digits
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    textValue = filtered
                }
                // Limit to 6 digits (0-999999)
                if filtered.count > 6 {
                    textValue = String(filtered.prefix(6))
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    validateAndClamp()
                }
            }
            .onChange(of: value) { _, newValue in
                // Sync text when value changes externally (e.g., slider or reset)
                if !isFocused {
                    textValue = String(newValue)
                }
            }
            .onAppear {
                textValue = String(value)
            }
    }
    
    private func validateAndClamp() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        guard let numValue = Int(textValue), !textValue.isEmpty else {
            // Empty or invalid - reset to current value
            textValue = String(value)
            return
        }
        
        if numValue < min {
            let formattedInput = formatter.string(from: NSNumber(value: numValue)) ?? "\(numValue)"
            let formattedMin = formatter.string(from: NSNumber(value: min)) ?? "\(min)"
            ToastManager.shared.show("\(formattedInput) is smaller than the minimum \(formattedMin).", duration: toastDuration)
            value = min
            textValue = String(min)
        } else if numValue > max {
            let formattedInput = formatter.string(from: NSNumber(value: numValue)) ?? "\(numValue)"
            let formattedMax = formatter.string(from: NSNumber(value: max)) ?? "\(max)"
            ToastManager.shared.show("\(formattedInput) is larger than the maximum \(formattedMax).", duration: toastDuration)
            value = max
            textValue = String(max)
        } else {
            value = numValue
            textValue = String(numValue)
        }
    }
}

// Double version for timeout/interval
struct ValidatedDoubleField: View {
    let placeholder: String
    @Binding var value: Double
    let min: Double
    let max: Double
    let toastDuration: TimeInterval
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    init(_ placeholder: String, value: Binding<Double>, min: Double, max: Double, toastDuration: TimeInterval = 2.0) {
        self.placeholder = placeholder
        self._value = value
        self.min = min
        self.max = max
        self.toastDuration = toastDuration
        self._textValue = State(initialValue: String(Int(value.wrappedValue)))
    }
    
    var body: some View {
        TextField(placeholder, text: $textValue)
            .keyboardType(.numberPad)
            .frame(width: 70)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focused($isFocused)
            .onChange(of: textValue) { _, newValue in
                // Only allow digits
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    textValue = filtered
                }
                // Limit to 6 digits (0-999999)
                if filtered.count > 6 {
                    textValue = String(filtered.prefix(6))
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    validateAndClamp()
                }
            }
            .onChange(of: value) { _, newValue in
                // Sync text when value changes externally (e.g., slider or reset)
                if !isFocused {
                    textValue = String(Int(newValue))
                }
            }
            .onAppear {
                textValue = String(Int(value))
            }
    }
    
    private func validateAndClamp() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        guard let numValue = Double(textValue), !textValue.isEmpty else {
            // Empty or invalid - reset to current value
            textValue = String(Int(value))
            return
        }
        
        if numValue < min {
            let formattedInput = formatter.string(from: NSNumber(value: Int(numValue))) ?? "\(Int(numValue))"
            let formattedMin = formatter.string(from: NSNumber(value: Int(min))) ?? "\(Int(min))"
            ToastManager.shared.show("\(formattedInput) is smaller than the minimum \(formattedMin).", duration: toastDuration)
            value = min
            textValue = String(Int(min))
        } else if numValue > max {
            let formattedInput = formatter.string(from: NSNumber(value: Int(numValue))) ?? "\(Int(numValue))"
            let formattedMax = formatter.string(from: NSNumber(value: Int(max))) ?? "\(Int(max))"
            ToastManager.shared.show("\(formattedInput) is larger than the maximum \(formattedMax).", duration: toastDuration)
            value = max
            textValue = String(Int(max))
        } else {
            value = numValue
            textValue = String(Int(numValue))
        }
    }
}

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
                            
                            ValidatedNumberField("TTL", value: $settings.ttl, min: settings.minTTL, max: settings.maxTTL)
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
                            
                            ValidatedDoubleField("ms", value: $settings.timeoutMs, min: settings.minTimeout, max: settings.maxTimeout)
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
                            
                            ValidatedDoubleField("ms", value: $settings.intervalMs, min: settings.minInterval, max: settings.maxInterval)
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
                            
                            ValidatedNumberField("bytes", value: $settings.packetSize, min: settings.minPacketSize, max: settings.maxPacketSize)
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
        .withToast()
    }
}

#Preview {
    SettingsView()
}
