//
//  ContentView.swift
//  VerticalTimeline
//
//  Created by Aleksands Zavalnijs on 26/02/2025.
//

import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        effectView.material = .sidebar
        effectView.blendingMode = .behindWindow
        return effectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // No updates needed
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            VisualEffectView()
                .ignoresSafeArea()
            
            VerticalTimelineView()
        }
    }
}

#Preview {
    ContentView()
}
