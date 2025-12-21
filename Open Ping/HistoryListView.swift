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
    var onSelect: (String) -> Void
    var onDelete: (String) -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(items, id: \.self) { domain in
                    Button(action: {
                        onSelect(domain)
                    }) {
                        Text(domain)
                    }
                    .id(domain) // stable ID for scrolling
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        onDelete(items[index])
                    }
                }
            }
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
        onSelect: { _ in },
        onDelete: { _ in }
    )
}
