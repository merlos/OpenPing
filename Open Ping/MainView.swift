//
//  MainView.swift
//  Open Ping
//
//  Created by Merlos on 12/25/24.
//

import SwiftUI

struct MainView: View {
    @State private var input: String = ""
    @State private var pingHistory: [String] = []
    @State private var showDetail = false
    @State private var selectedDomainOrIP: String?

    init(pingHistory: [String] = []) {
        _pingHistory = State(initialValue: pingHistory)
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Input Field
                TextField("Enter domain or IP", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: addDomainToHistory) {
                    Text("Ping")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // History List
                List {
                    ForEach(pingHistory, id: \.self) { domain in
                        Button(action: {
                            moveDomainToBeginning(domain)
                            selectedDomainOrIP = domain
                            showDetail = true
                        }) {
                            Text(domain)
                        }
                    }
                    .onDelete(perform: deleteFromHistory)
                }
                
                Spacer()
            }
            .navigationTitle("Open Ping")
            .toolbar {
                EditButton() // Add an Edit button for delete mode
            }
            .onAppear(perform: loadHistory)
        }
    }
    
    func loadHistory() {
        if let history = UserDefaults.standard.array(forKey: "PingHistory") as? [String] {
            pingHistory = history
        }
    }
    
    func moveDomainToBeginning(_ domain: String) {
        // Remove the domain if it already exists
        if let existingIndex = pingHistory.firstIndex(of: domain) {
            pingHistory.remove(at: existingIndex)
        }
        
        // Insert the domain at the beginning
        pingHistory.insert(domain, at: 0)
        
        // Save the updated history to UserDefaults
        saveHistory()
    }
    
    func addDomainToHistory() {
        // Trim spaces and convert to lowercase
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedInput.isEmpty else { return }

        moveDomainToBeginning(trimmedInput)
        
        // Update the selected domain and show detail
        selectedDomainOrIP = trimmedInput
        
        // Clear the TextField
        input = ""
        
        // Start pinging
        showDetail = true
    }
    
    func deleteFromHistory(at offsets: IndexSet) {
        pingHistory.remove(atOffsets: offsets)
        saveHistory()
    }
    
    func saveHistory() {
        UserDefaults.standard.set(pingHistory, forKey: "PingHistory")
    }
}

#Preview {
    MainView(pingHistory: ["google.com", "apple.com", "example.com"])
}
