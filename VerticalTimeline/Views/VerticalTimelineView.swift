//
//  VerticalTimelineView.swift
//  VerticalTimeline
//
//  Created by Aleksands Zavalnijs on 26/02/2025.
//

import SwiftUI

struct VerticalTimelineView: View {
    @StateObject private var todoManager = TodoManager()
    @State private var scrollToToday = true
    @State private var showingSettingsSheet = false
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(todoManager.allDates, id: \.self) { date in
                        DayView(date: date)
                            .id(date)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 1)
                            )
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 20)
            }
            .onAppear {
                if scrollToToday {
                    let today = Calendar.current.startOfDay(for: Date())
                    withAnimation {
                        scrollView.scrollTo(today, anchor: .top)
                    }
                    scrollToToday = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        let today = Calendar.current.startOfDay(for: Date())
                        withAnimation {
                            scrollView.scrollTo(today, anchor: .top)
                        }
                    }) {
                        Text("Today")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        todoManager.loadData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingSettingsSheet = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView(onSettingsSaved: {
                    // Reload data when settings are saved
                    todoManager.loadData()
                })
            }
            .alert("Error", isPresented: $todoManager.showErrorAlert) {
                Button("OK") {
                    todoManager.clearError()
                }
            } message: {
                Text("The app will use the default location in your Documents folder.\n\n\(todoManager.error?.localizedDescription ?? "Unknown error occurred")")
            }
        }
        .environmentObject(todoManager)
    }
}

#Preview {
    VerticalTimelineView()
} 