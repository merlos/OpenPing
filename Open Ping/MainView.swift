//
//  MainView.swift
//  Open Ping
//
//  Created by Merlos on 12/25/24.
//

import SwiftUI

struct MainView: View {
    @State private var input: String = ""
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var showDetail = false
    @State private var showSettings = false
    @State private var selectedDomainOrIP: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                VStack {
                    // Input Field
                    GlassmorphicCard {
                        TextField("Enter domain or IP", text: $input)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 28))
                            .padding()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    GlassmorphicCard {
                        Button(action: addDomainToHistory) {
                            Text("Ping")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.teal, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    HistoryListView(
                        items: historyManager.filteredHistory(for: input),
                        filter: input,
                        pinnedItems: historyManager.pinnedItems,
                        onSelect: { domain in
                            historyManager.add(domain)
                            selectedDomainOrIP = domain
                            showDetail = true
                        },
                        onDelete: { domain in
                            historyManager.remove(domain)
                        },
                        onTogglePin: { domain in
                            historyManager.togglePin(domain)
                        }
                    )
                    
                    Spacer()
                }
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
    MainView()
        //.environment(\.colorScheme, .dark) // Preview in Dark Mode
}
