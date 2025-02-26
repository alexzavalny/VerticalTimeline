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
    @State private var showingDatePicker = false
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                ZStack {
                    Color.clear
                    
                    LazyVStack(spacing: 20) {
                        ForEach(todoManager.allDates, id: \.self) { date in
                            DayView(date: date)
                                .id(date)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.windowBackgroundColor).opacity(0.7))
                                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 1)
                                )
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 20)
                }
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
                        showingDatePicker = true
                    }) {
                        Image(systemName: "calendar")
                    }
                    .popover(isPresented: $showingDatePicker, arrowEdge: .bottom) {
                        VStack {
                            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding()
                                .labelsHidden()
                            
                            Button("Go to Date") {
                                let selectedDateStart = Calendar.current.startOfDay(for: selectedDate)
                                withAnimation {
                                    scrollView.scrollTo(selectedDateStart, anchor: .top)
                                }
                                showingDatePicker = false
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom)
                        }
                        .frame(width: 300, height: 400)
                    }
                }
                
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