//
//  HistoryManager.swift
//  Open Ping
//
//  Created by Merlos on 12/25/24.
//

import SwiftUI

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var history: [String] = []
    @Published var pinnedItems: [String] = []
    private let storageKey = "PingHistory"
    private let pinnedStorageKey = "PinnedItems"
    
    init(history: [String]? = nil, pinned: [String]? = nil) {
        if let history = history {
            self.history = history
        } else {
            load()
        }
        if let pinned = pinned {
            self.pinnedItems = pinned
        } else {
            loadPinned()
        }
    }
    
    func load() {
        if let savedHistory = UserDefaults.standard.array(forKey: storageKey) as? [String] {
            history = savedHistory
        }
    }
    
    private func loadPinned() {
        if let savedPinned = UserDefaults.standard.array(forKey: pinnedStorageKey) as? [String] {
            pinnedItems = savedPinned
        }
    }
    
    private func save() {
        UserDefaults.standard.set(history, forKey: storageKey)
    }
    
    private func savePinned() {
        UserDefaults.standard.set(pinnedItems, forKey: pinnedStorageKey)
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
        // Also remove from pinned if it was pinned
        unpin(domain)
    }
    
    func isPinned(_ domain: String) -> Bool {
        pinnedItems.contains(domain)
    }
    
    func togglePin(_ domain: String) {
        if isPinned(domain) {
            unpin(domain)
        } else {
            pin(domain)
        }
    }
    
    func pin(_ domain: String) {
        guard !isPinned(domain) else { return }
        // Insert at the beginning so last pinned is first
        pinnedItems.insert(domain, at: 0)
        savePinned()
    }
    
    func unpin(_ domain: String) {
        if let index = pinnedItems.firstIndex(of: domain) {
            pinnedItems.remove(at: index)
            savePinned()
        }
    }
    
    func filteredHistory(for query: String) -> [String] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If searching, just return filtered results without pinned order
        guard trimmedQuery.isEmpty else {
            let matches = history.filter { $0.range(of: trimmedQuery, options: .caseInsensitive) != nil }
            return matches.isEmpty ? history : matches
        }
        
        // No search: show pinned items first, then unpinned
        let pinned = pinnedItems.filter { history.contains($0) }
        let unpinned = history.filter { !pinnedItems.contains($0) }
        return pinned + unpinned
    }
}
