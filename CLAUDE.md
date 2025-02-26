# VerticalTimeline Development Guide

## Build & Run Commands
- Build: `CMD+B` in Xcode
- Run: `CMD+R` in Xcode  
- Test: `CMD+U` in Xcode
- Test Single File: Select test file in navigator, run with `CMD+U`

## Code Style Guidelines
- **Architecture**: MVVM pattern with clean separation of models, views, and view models
- **File Organization**: Group files by type (Models, Views, Services, Utilities)
- **Naming**:
  - PascalCase for types (TodoManager, VerticalTimelineView)
  - camelCase for variables/functions (loadActiveTodos, dataFolderURL)
- **Error Handling**: Custom error enums, comprehensive guard statements
- **Documentation**: Add comments for public functions and complex logic
- **Patterns**:
  - Observer Pattern with `ObservableObject` and `@Published`
  - Singleton Pattern for service classes (e.g., TodoFileManager)
- **Swift Features**:
  - Use SwiftUI for all UI components
  - Leverage SwiftData for model annotations
  - Safe unwrapping with guard/if let over force unwrapping