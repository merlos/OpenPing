//
//  MainView.swift
//  Open Ping
//
//  Created by Merlos on 12/25/24.
//

import SwiftUI

struct MainView: View {
    @State private var input: String = ""
    @StateObject private var historyManager: HistoryManager
    @State private var showDetail = false
    @State private var showSettings = false
    @State private var selectedDomainOrIP: String?
    
    init(historyManager: HistoryManager = HistoryManager()) {
        _historyManager = StateObject(wrappedValue: historyManager)
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Input Field
                TextField("Enter domain or IP", text: $input)
                    .autocapitalization(.none) // Prevents automatic capitalization
                    .disableAutocorrection(true) // Disables autocorrection
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .font(.system(size: 28)) //
                    .frame(height: 88)
                
                Button(action: addDomainToHistory) {
                    Text("Ping")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.teal)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                HistoryListView(
                    items: historyManager.filteredHistory(for: input),
                    filter: input,
                    onSelect: { domain in
                        historyManager.add(domain)
                        selectedDomainOrIP = domain
                        showDetail = true
                    },
                    onDelete: { domain in
                        historyManager.remove(domain)
                    }
                )
                
                Spacer()
            }
            .navigationTitle("Open Ping")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            // NavigationDestination for PingView
            .navigationDestination(isPresented: $showDetail) {
                if let domainOrIP = selectedDomainOrIP {
                    PingView(domainOrIP: domainOrIP)
                }
            }
        }
    }
    
    func addDomainToHistory() {
        // Trim spaces and convert to lowercase
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedInput.isEmpty else { return }

        historyManager.add(trimmedInput)
        
        // Update the selected domain and show detail
        selectedDomainOrIP = trimmedInput
        
        // Clear the TextField
        input = ""
        
        // Start pinging
        showDetail = true
    }
}

#Preview {
    MainView(historyManager: HistoryManager(history: ["google.com", "apple.com", "example.com"]))
        //.environment(\.colorScheme, .dark) // Preview in Dark Mode
}
