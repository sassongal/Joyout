import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var dragHover = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.bubble.fill")
                            .foregroundColor(.blue)
                            .font(.title)
                        Text("JoyaaS")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text("Hebrew/English Text Processing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Operations List
                Text("TEXT OPERATIONS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ForEach(TextOperation.allCases) { operation in
                    OperationRow(
                        operation: operation,
                        isSelected: appState.selectedOperation == operation,
                        requiresAPIKey: operation.requiresAPIKey && appState.googleAIKey.isEmpty
                    )
                    .onTapGesture {
                        appState.selectedOperation = operation
                    }
                }
                
                Spacer()
                
                Divider()
                
                // Quick Actions
                VStack(spacing: 8) {
                    SidebarButton(title: "History", icon: "clock.fill") {
                        appState.showingHistory.toggle()
                    }
                    
                    SidebarButton(title: "Settings", icon: "gearshape.fill") {
                        appState.showingSettings.toggle()
                    }
                }
                .padding(.horizontal)
            }
            .frame(minWidth: 200)
            .padding(.vertical)
        } detail: {
            // Main Content
            VStack(spacing: 20) {
                // Header with operation info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: appState.selectedOperation.icon)
                                .foregroundColor(.blue)
                            Text(appState.selectedOperation.rawValue)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        Text(appState.selectedOperation.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if appState.selectedOperation.requiresAPIKey && appState.googleAIKey.isEmpty {
                        Button("Add API Key") {
                            appState.showingSettings = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Text Processing Area
                HStack(spacing: 20) {
                    // Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Input Text")
                            .font(.headline)
                        
                        TextEditor(text: $appState.inputText)
                            .font(.system(.body, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.textBackgroundColor))
                                    .stroke(dragHover ? Color.blue : Color.gray.opacity(0.3), lineWidth: dragHover ? 2 : 1)
                            )
                            .overlay(
                                Group {
                                    if appState.inputText.isEmpty {
                                        Text("Enter or paste text to process...")
                                            .foregroundColor(.secondary)
                                            .padding()
                                    }
                                }
                                , alignment: .topLeading
                            )
                            .onDrop(of: [.text, .fileURL], isTargeted: $dragHover) { providers in
                                handleDrop(providers: providers)
                            }
                    }
                    
                    // Process Button
                    VStack(spacing: 12) {
                        Spacer()
                        
                        Button(action: {
                            appState.processText()
                        }) {
                            VStack(spacing: 4) {
                                if appState.isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                }
                                
                                Text(appState.isProcessing ? "Processing..." : "Process")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(appState.inputText.isEmpty || appState.isProcessing)
                        .keyboardShortcut(.return, modifiers: .command)
                        
                        // Progress indicator for AI operations
                        if appState.isProcessing && appState.selectedOperation.requiresAPIKey {
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "network")
                                        .font(.caption2)
                                    Text("Calling AI...")
                                        .font(.caption2)
                                }
                                .foregroundColor(.blue)
                                
                                Text("This may take a moment")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Output
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Processed Result")
                                .font(.headline)
                            
                            Spacer()
                            
                            if !appState.outputText.isEmpty {
                                Button("Copy") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(appState.outputText, forType: .string)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        
                        ScrollView {
                            Text(appState.outputText.isEmpty ? "Processed text will appear here..." : appState.outputText)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(appState.outputText.isEmpty ? .secondary : .primary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(appState.outputText.isEmpty ? Color(NSColor.controlBackgroundColor) : Color(NSColor.textBackgroundColor))
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .frame(maxHeight: .infinity)
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $appState.showingSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showingHistory) {
            HistoryView()
                .environmentObject(appState)
        }
        // Note: Toolbar functionality is available via sidebar buttons and menu commands
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        do {
                            let content = try String(contentsOf: url)
                            DispatchQueue.main.async {
                                appState.inputText = content
                            }
                        } catch {
                            print("Error reading file: \(error)")
                        }
                    }
                }
                return true
            } else if provider.hasItemConformingToTypeIdentifier("public.text") {
                provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, error in
                    if let text = item as? String {
                        DispatchQueue.main.async {
                            appState.inputText = text
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}

// MARK: - Supporting Views
struct OperationRow: View {
    let operation: TextOperation
    let isSelected: Bool
    let requiresAPIKey: Bool
    
    var body: some View {
        HStack {
            Image(systemName: operation.icon)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(operation.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                if requiresAPIKey {
                    Text("Requires API Key")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .orange)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .opacity(requiresAPIKey ? 0.6 : 1.0)
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                    .font(.subheadline)
                Spacer()
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.clear)
        )
        .onHover { hovering in
            // Add hover effect if needed
        }
    }
}
