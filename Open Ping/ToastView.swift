//
//  ToastView.swift
//  Open Ping
//
//  Created by Merlos on 1/4/26.
//

import SwiftUI

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// Toast Manager to handle showing/hiding toasts
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var isShowing = false
    @Published var message = ""
    
    private var dismissTask: Task<Void, Never>?
    
    func show(_ message: String, duration: TimeInterval = 2.0) {
        // Cancel any existing dismiss task
        dismissTask?.cancel()
        
        DispatchQueue.main.async {
            self.message = message
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isShowing = true
            }
        }
        
        // Schedule dismiss
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isShowing = false
                    }
                }
            }
        }
    }
    
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowing = false
        }
    }
}

// View modifier to add toast capability to any view
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if toastManager.isShowing {
                ToastView(message: toastManager.message)
                    .padding(.top, 50)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }
}

extension View {
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}

#Preview {
    VStack {
        ToastView(message: "14,003 is larger than the maximum 1,500.")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.3))
}
