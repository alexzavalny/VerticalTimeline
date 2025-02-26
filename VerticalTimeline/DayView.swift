//
//  DayView.swift
//  VerticalTimeline
//
//  Created by Aleksands Zavalnijs on 26/02/2025.
//

import SwiftUI

struct DayView: View {
    @EnvironmentObject var todoManager: TodoManager
    let date: Date
    @State private var showingAddTodoSheet = false
    @State private var newTodoText = ""
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full weekday name
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day header
            HStack {
                VStack(alignment: .leading) {
                    Text(date, style: .date)
                        .font(.headline)
                        .foregroundColor(isToday ? .blue : .primary)
                    
                    Text(weekdayString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingAddTodoSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            // Todos for this day
            VStack(alignment: .leading, spacing: 8) {
                let (activeTodos, completedTodos) = todoManager.getTodosForDate(date)
                
                // Active todos
                ForEach(activeTodos) { todo in
                    TodoRow(todo: todo, date: date)
                }
                
                // Completed todos
                ForEach(completedTodos) { todo in
                    TodoRow(todo: todo, date: date)
                }
                
                if activeTodos.isEmpty && completedTodos.isEmpty {
                    Text("No todos for this day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showingAddTodoSheet) {
            // Add new todo sheet
            VStack(spacing: 16) {
                Text("Add New Todo")
                    .font(.headline)
                    .padding()
                
                TextField("Enter todo title", text: $newTodoText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                HStack {
                    Button("Cancel") {
                        newTodoText = ""
                        showingAddTodoSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Add") {
                        if !newTodoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            todoManager.addTodo(newTodoText, forDate: date)
                            newTodoText = ""
                            showingAddTodoSheet = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTodoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .presentationDetents([.height(200)])
        }
    }
}

struct TodoRow: View {
    @EnvironmentObject var todoManager: TodoManager
    let todo: Todo
    let date: Date
    
    var body: some View {
        HStack {
            Button(action: {
                if !todo.isCompleted {
                    todoManager.completeTodo(todo, forDate: date)
                }
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(todo.isCompleted ? .green : .primary)
            }
            .buttonStyle(.plain)
            
            Text(todo.title)
                .strikethrough(todo.isCompleted)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)
            
            Spacer()
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
}

#Preview {
    DayView(date: Date())
        .environmentObject(TodoManager())
} 