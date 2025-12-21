//
//  HistoryManager.swift
//  Open Ping
//
//  Created by Merlos on 12/25/24.
//

import SwiftUI

class HistoryManager: ObservableObject {
    @Published var history: [String] = []
    private let storageKey = "PingHistory"
    
    init(history: [String]? = nil) {
        if let history = history {
            self.history = history
        } else {
            load()
        }
    }
    
    func load() {
        if let savedHistory = UserDefaults.standard.array(forKey: storageKey) as? [String] {
            history = savedHistory
        }
    }
    
    private func save() {
        UserDefaults.standard.set(history, forKey: storageKey)
    }
    
    func add(_ domain: String) {
        let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        
        // Remove if exists to move to top
        if let index = history.firstIndex(of: trimmed) {
            history.remove(at: index)
        }
        
        history.insert(trimmed, at: 0)
        save()
    }
    
    func remove(_ domain: String) {
        if let index = history.firstIndex(of: domain) {
            history.remove(at: index)
            save()
        }
    }
    
    func filteredHistory(for query: String) -> [String] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return history }
        let matches = history.filter { $0.range(of: trimmedQuery, options: .caseInsensitive) != nil }
        return matches.isEmpty ? history : matches
    }
}
