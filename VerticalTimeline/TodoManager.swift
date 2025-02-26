//
//  TodoManager.swift
//  VerticalTimeline
//
//  Created by Aleksands Zavalnijs on 26/02/2025.
//

import Foundation
import SwiftUI

class TodoManager: ObservableObject {
    @Published var activeTodos: [Todo] = []
    @Published var completedTodosByDate: [Date: [Todo]] = [:]
    @Published var allDates: [Date] = []
    
    private let fileManager = TodoFileManager.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Load active todos
        activeTodos = fileManager.loadActiveTodos()
        
        // Load dates with completed todos
        let dates = fileManager.getAllDaysWithCompletedTodos()
        
        // Include today and any date with completed todos
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var allDatesSet = Set(dates)
        allDatesSet.insert(today)
        
        // Create a list of dates from today-30 days to today+30 days for scrolling
        var dateRange: [Date] = []
        for day in -30...30 {
            if let date = calendar.date(byAdding: .day, value: day, to: today) {
                dateRange.append(date)
                allDatesSet.insert(date)
            }
        }
        
        // Sort the dates
        allDates = Array(allDatesSet).sorted()
        
        // Load completed todos for each date
        completedTodosByDate = [:]
        for date in dates {
            let startOfDay = calendar.startOfDay(for: date)
            let completedTodos = fileManager.loadCompletedTodos(forDate: startOfDay)
            if !completedTodos.isEmpty {
                completedTodosByDate[startOfDay] = completedTodos
            }
        }
    }
    
    // Mark a todo as completed for a specific date
    func completeTodo(_ todo: Todo, forDate date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Create a completed todo
        let completedTodo = Todo(title: todo.title, isCompleted: true, date: startOfDay)
        
        // Add to completed todos for this date
        if completedTodosByDate[startOfDay] != nil {
            completedTodosByDate[startOfDay]?.append(completedTodo)
        } else {
            completedTodosByDate[startOfDay] = [completedTodo]
        }
        
        // Remove from active todos if it exists there
        if let index = activeTodos.firstIndex(where: { $0.id == todo.id }) {
            activeTodos.remove(at: index)
        }
        
        // Save changes
        saveChanges(forDate: startOfDay)
    }
    
    // Add a new active todo
    func addTodo(_ title: String, forDate date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let newTodo = Todo(title: title, date: startOfDay)
        activeTodos.append(newTodo)
        saveChanges(forDate: startOfDay)
    }
    
    // Move incomplete todos to the next day
    func moveIncompleteTodosToNextDay(fromDate date: Date) {
        // This would be called at midnight or app startup
        // We don't actually need to change anything in our data model
        // as incomplete todos are automatically considered for "today"
        saveChanges(forDate: date)
    }
    
    // Save all changes to files
    private func saveChanges(forDate date: Date? = nil) {
        // Save active todos
        fileManager.saveActiveTodos(activeTodos)
        
        // Save completed todos for the specified date
        if let date = date, let completedTodos = completedTodosByDate[date] {
            fileManager.saveCompletedTodos(completedTodos, forDate: date)
        }
    }
    
    // Get todos for a specific date (both active and completed)
    func getTodosForDate(_ date: Date) -> (active: [Todo], completed: [Todo]) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        
        // For today and future dates, show active todos
        let activeTodosForDate: [Todo]
        if startOfDay >= today {
            activeTodosForDate = activeTodos
        } else {
            activeTodosForDate = []
        }
        
        // Get completed todos for this date
        let completedTodosForDate = completedTodosByDate[startOfDay] ?? []
        
        return (activeTodosForDate, completedTodosForDate)
    }
} 