import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPath: String
    @State private var isShowingFolderPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isDefaultFolderActive = false
    
    // A closure to call when settings are saved
    var onSettingsSaved: () -> Void
    
    init(onSettingsSaved: @escaping () -> Void) {
        self.onSettingsSaved = onSettingsSaved
        // Get initial value from TodoFileManager
        _currentPath = State(initialValue: TodoFileManager.shared.getCurrentDataFolderPath())
        _isDefaultFolderActive = State(initialValue: TodoFileManager.shared.isUsingDefaultFolder)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Todo Data Folder")
                    .font(.headline)
                
                if isDefaultFolderActive {
                    Text("Currently using default folder")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.bottom, 4)
                }
                
                HStack {
                    Text(currentPath)
                        .foregroundColor(.secondary)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .frame(minWidth: 100)
                    
                    Spacer()
                    
                    Button("Browse...") {
                        isShowingFolderPicker = true
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Note: The app will need access to this folder every time it launches.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("If you select a folder outside your Documents directory, you may need to grant permission each time the app starts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("If access fails, the app will use a default folder in your Documents directory.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save") {
                    dismiss()
                    // Reload data after settings change
                    onSettingsSaved()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 300)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .fileImporter(
            isPresented: $isShowingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else { return }
                
                // Try to access the security-scoped resource
                guard selectedURL.startAccessingSecurityScopedResource() else {
                    showError = true
                    errorMessage = "Unable to access the selected folder. Please choose another location or check folder permissions."
                    return
                }
                
                // Safe to stop accessing here since TodoFileManager will start accessing it again
                selectedURL.stopAccessingSecurityScopedResource()
                
                do {
                    // Change the data folder - this will also create the security bookmark
                    try TodoFileManager.shared.changeDataFolder(to: selectedURL)
                    currentPath = TodoFileManager.shared.getCurrentDataFolderPath()
                    isDefaultFolderActive = TodoFileManager.shared.isUsingDefaultFolder
                } catch let folderError as TodoFileManagerError {
                    showError = true
                    errorMessage = folderError.localizedDescription
                } catch {
                    showError = true
                    errorMessage = "Failed to set folder: \(error.localizedDescription)"
                }
                
            case .failure(let error):
                showError = true
                errorMessage = "Folder selection failed: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    SettingsView(onSettingsSaved: {})
} 