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
    
    // Computed filtered list based on input (case-insensitive contains)
    private var filteredHistory: [String] {
        let query = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return pingHistory }
        let matches = pingHistory.filter { $0.range(of: query, options: .caseInsensitive) != nil }
        return matches.isEmpty ? pingHistory : matches
    }

    // Track the ID of the first item to enable scrolling to top
    @State private var topItemID: String? = nil

    init(pingHistory: [String] = []) {
        _pingHistory = State(initialValue: pingHistory)
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
                
                ScrollViewReader { proxy in
                    List {
                        ForEach(filteredHistory, id: \.self) { domain in
                            Button(action: {
                                moveDomainToBeginning(domain)
                                selectedDomainOrIP = domain
                                showDetail = true
                            }) {
                                Text(domain)
                            }
                            .id(domain) // stable ID for scrolling
                        }
                        .onDelete(perform: deleteFromHistory)
                    }
                    .onChange(of: input) { _, _ in
                        // When typing, attempt to scroll to the first filtered item
                        if let first = filteredHistory.first {
                            withAnimation {
                                proxy.scrollTo(first, anchor: .top)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Open Ping")
            .toolbar {
                EditButton() // Add an Edit button for delete mode
            }
            .onAppear(perform: loadHistory)
            .onAppear {
                topItemID = pingHistory.first
            }
            // NavigationDestination for PingView
            .navigationDestination(isPresented: $showDetail) {
                if let domainOrIP = selectedDomainOrIP {
                    PingView(domainOrIP: domainOrIP)
                }
            }
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
        //.environment(\.colorScheme, .dark) // Preview in Dark Mode
}
