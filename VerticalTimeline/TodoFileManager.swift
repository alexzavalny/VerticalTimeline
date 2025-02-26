//
//  TodoFileManager.swift
//  VerticalTimeline
//
//  Created by Aleksands Zavalnijs on 26/02/2025.
//

import Foundation

// Error types for TodoFileManager
enum TodoFileManagerError: Error, LocalizedError {
    case folderAccessDenied(URL)
    case folderCreationFailed(URL, Error)
    case bookmarkCreationFailed(URL, Error)
    case fileAccessError(URL, Error)
    case invalidFolder(URL)
    
    var errorDescription: String? {
        switch self {
        case .folderAccessDenied(let url):
            return "Cannot access folder at: \(url.path). Permission denied."
        case .folderCreationFailed(let url, let error):
            return "Failed to create folder at: \(url.path). Error: \(error.localizedDescription)"
        case .bookmarkCreationFailed(let url, let error):
            return "Failed to create security bookmark for: \(url.path). Error: \(error.localizedDescription)"
        case .fileAccessError(let url, let error):
            return "Failed to access file at: \(url.path). Error: \(error.localizedDescription)"
        case .invalidFolder(let url):
            return "The folder at \(url.path) is invalid or no longer exists."
        }
    }
}

class TodoFileManager {
    static let shared = TodoFileManager()
    
    private let fileManager = FileManager.default
    private(set) var dataFolderURL: URL
    private let activeTodosFilename = "todo.md"
    
    // UserDefaults keys
    private let dataFolderKey = "TodoDataFolderPath"
    private let dataFolderBookmarkKey = "TodoDataFolderBookmark"
    
    // Keep track of whether we're accessing a security-scoped resource
    private var isAccessingSecurityScopedResource = false
    
    // Add a property to notify if we're falling back to default folder
    private(set) var isUsingDefaultFolder = false
    
    private init() {
        // Default location - Documents/TodoData
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let defaultFolder = documentsDirectory.appendingPathComponent("TodoData")
        
        // Initialize with default folder
        self.dataFolderURL = defaultFolder
        self.isUsingDefaultFolder = true
        
        do {
            // Try to get saved folder from bookmark
            if let bookmarkData = UserDefaults.standard.data(forKey: dataFolderBookmarkKey) {
                do {
                    var isStale = false
                    let url = try URL(resolvingBookmarkData: bookmarkData,
                                    options: .withSecurityScope,
                                    relativeTo: nil,
                                    bookmarkDataIsStale: &isStale)
                    
                    // If successfully resolved the bookmark, try to access the URL
                    if url.startAccessingSecurityScopedResource() {
                        isAccessingSecurityScopedResource = true
                        
                        // Check if folder exists
                        if fileManager.fileExists(atPath: url.path) {
                            self.dataFolderURL = url
                            self.isUsingDefaultFolder = false
                            print("Successfully accessed folder from bookmark: \(url.path)")
                        } else {
                            url.stopAccessingSecurityScopedResource()
                            isAccessingSecurityScopedResource = false
                            print("Folder from bookmark no longer exists, using default")
                            throw TodoFileManagerError.invalidFolder(url)
                        }
                    } else {
                        // Couldn't access the URL
                        print("Could not access security-scoped resource, using default folder")
                        throw TodoFileManagerError.folderAccessDenied(url)
                    }
                    
                    // If bookmark is stale, update it
                    if isStale && isAccessingSecurityScopedResource && fileManager.fileExists(atPath: url.path) {
                        try updateBookmarkFor(url: url)
                    }
                } catch {
                    // If there's an error resolving the bookmark, use the default folder
                    print("Error resolving bookmark, using default folder: \(error)")
                    // Continue execution with default folder
                }
            } else if let savedPath = UserDefaults.standard.string(forKey: dataFolderKey),
                    let url = URL(string: savedPath),
                    fileManager.fileExists(atPath: url.path) {
                // For backward compatibility with the old method
                do {
                    // Try to access the URL first
                    if url.startAccessingSecurityScopedResource() {
                        isAccessingSecurityScopedResource = true
                        self.dataFolderURL = url
                        self.isUsingDefaultFolder = false
                        
                        // Try to create a bookmark for next time
                        try updateBookmarkFor(url: url)
                    } else {
                        throw TodoFileManagerError.folderAccessDenied(url)
                    }
                } catch {
                    print("Could not create bookmark or access folder: \(error)")
                    // If we can't access it, just fall back to default
                    if isAccessingSecurityScopedResource {
                        url.stopAccessingSecurityScopedResource()
                        isAccessingSecurityScopedResource = false
                    }
                }
            }
            
            // Ensure folder exists
            try createDataFolderIfNeeded()
        } catch {
            print("Error during initialization, using default folder: \(error)")
            // If any error occurred, make sure we're using default folder
            self.dataFolderURL = defaultFolder
            self.isUsingDefaultFolder = true
            
            // Try to create default folder
            do {
                try createDataFolderIfNeeded()
            } catch {
                print("Critical error: Could not create even default folder: \(error)")
            }
        }
    }
    
    deinit {
        // Make sure to stop accessing when the manager is deallocated
        if isAccessingSecurityScopedResource {
            dataFolderURL.stopAccessingSecurityScopedResource()
        }
    }
    
    private func createDataFolderIfNeeded() throws {
        do {
            if !fileManager.fileExists(atPath: dataFolderURL.path) {
                try fileManager.createDirectory(at: dataFolderURL, withIntermediateDirectories: true)
            }
        } catch {
            print("Error creating data directory: \(error)")
            
            // If there was an error, fall back to the default folder
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let defaultFolder = documentsDirectory.appendingPathComponent("TodoData")
            
            // Since we're switching to a default folder, we're no longer accessing a security-scoped resource
            if isAccessingSecurityScopedResource {
                // Stop accessing the previous folder first
                dataFolderURL.stopAccessingSecurityScopedResource()
                isAccessingSecurityScopedResource = false
            }
            
            // Set to default folder
            self.dataFolderURL = defaultFolder
            self.isUsingDefaultFolder = true
            
            // Try again with the default folder
            do {
                if !fileManager.fileExists(atPath: dataFolderURL.path) {
                    try fileManager.createDirectory(at: dataFolderURL, withIntermediateDirectories: true)
                }
            } catch {
                print("Critical error creating default data directory: \(error)")
                throw TodoFileManagerError.folderCreationFailed(defaultFolder, error)
            }
        }
    }
    
    private func updateBookmarkFor(url: URL) throws {
        do {
            // Create a new bookmark
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                includingResourceValuesForKeys: nil,
                                                relativeTo: nil)
            
            // Save the bookmark data to UserDefaults
            UserDefaults.standard.set(bookmarkData, forKey: dataFolderBookmarkKey)
        } catch {
            print("Error creating bookmark: \(error)")
            throw TodoFileManagerError.bookmarkCreationFailed(url, error)
        }
    }
    
    // Method to change the data folder - now throws errors
    func changeDataFolder(to newFolderURL: URL) throws {
        // Stop accessing the previous folder if we were using a security-scoped resource
        if isAccessingSecurityScopedResource {
            dataFolderURL.stopAccessingSecurityScopedResource()
            isAccessingSecurityScopedResource = false
        }
        
        // Test access to the new folder
        if !newFolderURL.startAccessingSecurityScopedResource() {
            throw TodoFileManagerError.folderAccessDenied(newFolderURL)
        }
        
        isAccessingSecurityScopedResource = true
        
        // Update the data folder URL
        dataFolderURL = newFolderURL
        isUsingDefaultFolder = false
        
        // Save to UserDefaults
        UserDefaults.standard.set(newFolderURL.absoluteString, forKey: dataFolderKey)
        
        // Create a bookmark for persistent access
        do {
            try updateBookmarkFor(url: newFolderURL)
            print("Successfully created bookmark for: \(newFolderURL.path)")
        } catch {
            print("Error creating bookmark: \(error)")
            throw error // Re-throw the error from updateBookmarkFor
        }
        
        // Create folder if needed
        try createDataFolderIfNeeded()
    }
    
    // Get the current data folder path in a human-readable format
    func getCurrentDataFolderPath() -> String {
        return dataFolderURL.path
    }
    
    // MARK: - Active Todos
    
    func saveActiveTodos(_ todos: [Todo]) throws {
        let todoStrings = todos.map { "- [ ] \($0.title)" }
        let fileContent = todoStrings.joined(separator: "\n")
        
        do {
            let fileURL = dataFolderURL.appendingPathComponent(activeTodosFilename)
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving active todos: \(error)")
            throw TodoFileManagerError.fileAccessError(dataFolderURL.appendingPathComponent(activeTodosFilename), error)
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
    
    func saveCompletedTodos(_ todos: [Todo], forDate date: Date) throws {
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
            throw TodoFileManagerError.fileAccessError(dataFolderURL.appendingPathComponent(filename), error)
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