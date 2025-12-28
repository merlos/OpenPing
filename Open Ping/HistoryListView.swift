//
//  HistoryListView.swift
//  Open Ping
//
//  Created by Merlos on 12/25/24.
//

import SwiftUI

struct HistoryListView: View {
    var items: [String]
    var filter: String
    var pinnedItems: Set<String>
    var onSelect: (String) -> Void
    var onDelete: (String) -> Void
    var onTogglePin: (String) -> Void
    
    init(items: [String], filter: String, pinnedItems: [String] = [], onSelect: @escaping (String) -> Void, onDelete: @escaping (String) -> Void, onTogglePin: @escaping (String) -> Void = { _ in }) {
        self.items = items
        self.filter = filter
        self.pinnedItems = Set(pinnedItems)
        self.onSelect = onSelect
        self.onDelete = onDelete
        self.onTogglePin = onTogglePin
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(items, id: \.self) { domain in
                    HStack {
                        Text(domain)
                        Spacer()
                        if pinnedItems.contains(domain) {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .contentShape(Rectangle()) // Make entire row tappable
                    .onTapGesture {
                        onSelect(domain)
                    }
                    .onLongPressGesture {
                        onTogglePin(domain)
                    }
                    .id(domain) // stable ID for scrolling
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        onDelete(items[index])
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(.clear)
            .onChange(of: filter) { _, _ in
                // When typing, attempt to scroll to the first filtered item
                if let first = items.first {
                    withAnimation {
                        proxy.scrollTo(first, anchor: .top)
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryListView(
        items: ["google.com", "apple.com", "example.com"],
        filter: "",
        pinnedItems: ["google.com"],
        onSelect: { _ in },
        onDelete: { _ in },
        onTogglePin: { _ in }
    )
}
