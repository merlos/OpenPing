//
//  ContentView.swift
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
        NavigationView {
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
                            selectedDomainOrIP = domain
                            showDetail = true
                        }) {
                            Text(domain)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Open Ping")
            .onAppear(perform: loadHistory)
            .background(
                NavigationLink(
                    destination: PingView(domainOrIP: selectedDomainOrIP ?? ""),
                    isActive: $showDetail,
                    label: { EmptyView() }
                )
                .hidden()
            )
        }
    }
    
    func loadHistory() {
        if let history = UserDefaults.standard.array(forKey: "PingHistory") as? [String] {
            pingHistory = history
        }
    }
    
    func addDomainToHistory() {
        guard !input.isEmpty else { return }
        
        if !pingHistory.contains(input) {
            pingHistory.append(input)
            UserDefaults.standard.set(pingHistory, forKey: "PingHistory")
        }
        
        selectedDomainOrIP = input
        showDetail = true
    }
}

#Preview {
    MainView(pingHistory: ["google.com", "apple.com", "example.com"])

}
