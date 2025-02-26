//
//  VerticalTimelineApp.swift
//  VerticalTimeline
//
//  Created by Aleksands Zavalnijs on 26/02/2025.
//

import SwiftUI
import SwiftData

@main
struct VerticalTimelineApp: App {
    // Add a state object to initialize the TodoManager at app startup
    // This helps ensure it's loaded before the view needs it
    @StateObject private var todoManager = TodoManager()
    
    // Initialize the file manager explicitly before app runs
    init() {
        // Ensure the file manager is initialized before the app runs
        // Force access to the shared instance but catch any errors
        do {
            _ = TodoFileManager.shared
        } catch {
            print("Error initializing TodoFileManager: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            VerticalTimelineView()
                .frame(minWidth: 350, idealWidth: 400, maxWidth: 450)
                .environmentObject(todoManager)
                .onAppear {
                    // Force the TodoManager to reload data on app appear
                    todoManager.loadData()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
