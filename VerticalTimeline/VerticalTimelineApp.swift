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
    var body: some Scene {
        WindowGroup {
            VerticalTimelineView()
                .frame(minWidth: 350, idealWidth: 400, maxWidth: 450)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
