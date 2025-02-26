//
//  Todo.swift
//  VerticalTimeline
//
//  Created by Aleksands Zavalnijs on 26/02/2025.
//

import Foundation
import SwiftData

@Model
final class Todo {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var date: Date
    
    init(title: String, isCompleted: Bool = false, date: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.date = date
    }
}
