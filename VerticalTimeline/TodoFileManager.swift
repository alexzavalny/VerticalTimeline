//
//  TodoFileManager.swift
//  VerticalTimeline
//
//  Created by Aleksands Zavalnijs on 26/02/2025.
//

import Foundation

class TodoFileManager {
    static let shared = TodoFileManager()
    
    private let fileManager = FileManager.default
    private var dataFolderURL: URL
    private let activeTodosFilename = "todo.md"
    
    private init() {
        // Create application data directory if it doesn't exist
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dataFolderURL = documentsDirectory.appendingPathComponent("TodoData")
        
        do {
            if !fileManager.fileExists(atPath: dataFolderURL.path) {
                try fileManager.createDirectory(at: dataFolderURL, withIntermediateDirectories: true)
            }
        } catch {
            print("Error creating data directory: \(error)")
        }
    }
    
    // MARK: - Active Todos
    
    func saveActiveTodos(_ todos: [Todo]) {
        let todoStrings = todos.map { "- [ ] \($0.title)" }
        let fileContent = todoStrings.joined(separator: "\n")
        
        do {
            let fileURL = dataFolderURL.appendingPathComponent(activeTodosFilename)
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving active todos: \(error)")
        }
    }
    
    func loadActiveTodos() -> [Todo] {
        let fileURL = dataFolderURL.appendingPathComponent(activeTodosFilename)
        
        do {
            if !fileManager.fileExists(atPath: fileURL.path) {
                return []
            }
            
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let todoLines = content.components(separatedBy: .newlines)
            
            return todoLines.compactMap { line in
                guard !line.isEmpty, line.hasPrefix("- [ ]") else { return nil }
                let title = line.replacingOccurrences(of: "- [ ] ", with: "")
                return Todo(title: title)
            }
        } catch {
            print("Error loading active todos: \(error)")
            return []
        }
    }
    
    // MARK: - Completed Todos
    
    func saveCompletedTodos(_ todos: [Todo], forDate date: Date) {
        guard !todos.isEmpty else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        let filename = "\(dateString).md"
        
        let todoStrings = todos.map { "- [x] \($0.title)" }
        let fileContent = todoStrings.joined(separator: "\n")
        
        do {
            let fileURL = dataFolderURL.appendingPathComponent(filename)
            let existingContent = fileManager.fileExists(atPath: fileURL.path) ?
                (try? String(contentsOf: fileURL, encoding: .utf8)) ?? "" : ""
            
            let newContent = existingContent.isEmpty ? fileContent : existingContent + "\n" + fileContent
            try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving completed todos for \(dateString): \(error)")
        }
    }
    
    func loadCompletedTodos(forDate date: Date) -> [Todo] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        let filename = "\(dateString).md"
        let fileURL = dataFolderURL.appendingPathComponent(filename)
        
        do {
            if !fileManager.fileExists(atPath: fileURL.path) {
                return []
            }
            
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let todoLines = content.components(separatedBy: .newlines)
            
            return todoLines.compactMap { line in
                guard !line.isEmpty, line.hasPrefix("- [x]") else { return nil }
                let title = line.replacingOccurrences(of: "- [x] ", with: "")
                return Todo(title: title, isCompleted: true, date: date)
            }
        } catch {
            print("Error loading completed todos for \(dateString): \(error)")
            return []
        }
    }
    
    // Gets a list of all days with completed todos
    func getAllDaysWithCompletedTodos() -> [Date] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: dataFolderURL, includingPropertiesForKeys: nil)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            return fileURLs.compactMap { url in
                let filename = url.lastPathComponent
                guard filename != activeTodosFilename, filename.hasSuffix(".md") else { return nil }
                let dateString = filename.replacingOccurrences(of: ".md", with: "")
                return formatter.date(from: dateString)
            }.sorted()
            
        } catch {
            print("Error getting days with completed todos: \(error)")
            return []
        }
    }
} 