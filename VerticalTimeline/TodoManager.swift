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
    
    // Add error handling
    @Published var error: Error? = nil
    @Published var showErrorAlert = false
    
    private let fileManager = TodoFileManager.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Clear any previous errors
        error = nil
        
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
        
        // Show a message if we're using default folder and had to fall back
        if fileManager.isUsingDefaultFolder {
            self.error = TodoFileManagerError.folderAccessDenied(fileManager.dataFolderURL)
            self.showErrorAlert = true
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
        do {
            try saveChanges(forDate: startOfDay)
        } catch {
            self.error = error
            self.showErrorAlert = true
            print("Error completing todo: \(error)")
        }
    }
    
    // Add a new active todo
    func addTodo(_ title: String, forDate date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let newTodo = Todo(title: title, date: startOfDay)
        activeTodos.append(newTodo)
        
        do {
            try saveChanges(forDate: startOfDay)
        } catch {
            self.error = error
            self.showErrorAlert = true
            print("Error adding todo: \(error)")
        }
    }
    
    // Move incomplete todos to the next day
    func moveIncompleteTodosToNextDay(fromDate date: Date) {
        // This would be called at midnight or app startup
        // We don't actually need to change anything in our data model
        // as incomplete todos are automatically considered for "today"
        do {
            try saveChanges(forDate: date)
        } catch {
            self.error = error
            self.showErrorAlert = true
            print("Error moving todos: \(error)")
        }
    }
    
    // Save all changes to files
    private func saveChanges(forDate date: Date? = nil) throws {
        // Save active todos
        try fileManager.saveActiveTodos(activeTodos)
        
        // Save completed todos for the specified date
        if let date = date, let completedTodos = completedTodosByDate[date] {
            try fileManager.saveCompletedTodos(completedTodos, forDate: date)
        }
    }
    
    // Get todos for a specific date (both active and completed)
    func getTodosForDate(_ date: Date) -> (active: [Todo], completed: [Todo]) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        
        // For today's view, show all todos scheduled for today or earlier (past todos roll over to today)
        // For future days, only show todos specifically scheduled for that day
        // For past days, don't show active todos (they would have rolled over to today)
        let activeTodosForDate: [Todo]
        if startOfDay == today {
            // For today's view, include todos scheduled for today or earlier
            activeTodosForDate = activeTodos.filter { todo ->
                Bool in
                let todoDate = calendar.startOfDay(for: todo.date)
                return todoDate <= today
            }
        } else if startOfDay > today {
            // For future dates, only show todos scheduled for that specific date
            activeTodosForDate = activeTodos.filter { todo ->
                Bool in
                let todoDate = calendar.startOfDay(for: todo.date)
                return todoDate == startOfDay
            }
        } else {
            // For past dates, don't show active todos
            activeTodosForDate = []
        }
        
        // Get completed todos for this date
        let completedTodosForDate = completedTodosByDate[startOfDay] ?? []
        
        return (activeTodosForDate, completedTodosForDate)
    }
    
    // Method to clear errors
    func clearError() {
        self.error = nil
        self.showErrorAlert = false
    }
    
    // Undo a completed todo (move it back to active todos)
    func undoCompletedTodo(_ todo: Todo, fromDate date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Remove from completed todos
        if var completedTodos = completedTodosByDate[startOfDay] {
            if let index = completedTodos.firstIndex(where: { $0.id == todo.id }) {
                completedTodos.remove(at: index)
                completedTodosByDate[startOfDay] = completedTodos
                
                // Add back to active todos with isCompleted set to false
                let activeTodo = Todo(title: todo.title, isCompleted: false, date: startOfDay)
                activeTodos.append(activeTodo)
                
                // Save changes
                do {
                    try saveChanges(forDate: startOfDay)
                } catch {
                    self.error = error
                    self.showErrorAlert = true
                    print("Error undoing completed todo: \(error)")
                }
            }
        }
    }
    
    // Delete a todo (from either active or completed)
    func deleteTodo(_ todo: Todo, fromDate date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Check if it's in active todos
        if let index = activeTodos.firstIndex(where: { $0.id == todo.id }) {
            activeTodos.remove(at: index)
        }
        
        // Check if it's in completed todos
        if var completedTodos = completedTodosByDate[startOfDay] {
            if let index = completedTodos.firstIndex(where: { $0.id == todo.id }) {
                completedTodos.remove(at: index)
                completedTodosByDate[startOfDay] = completedTodos
            }
        }
        
        // Save changes
        do {
            try saveChanges(forDate: startOfDay)
        } catch {
            self.error = error
            self.showErrorAlert = true
            print("Error deleting todo: \(error)")
        }
    }
} 
