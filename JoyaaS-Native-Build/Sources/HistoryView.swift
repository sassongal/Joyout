import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedRecord: ProcessingRecord?
    
    var filteredHistory: [ProcessingRecord] {
        if searchText.isEmpty {
            return appState.processingHistory
        } else {
            return appState.processingHistory.filter { record in
                record.input.lowercased().contains(searchText.lowercased()) ||
                record.output.lowercased().contains(searchText.lowercased()) ||
                record.operation.rawValue.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                    .font(.title)
                Text("Processing History")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Clear All") {
                    appState.processingHistory.removeAll()
                }
                .disabled(appState.processingHistory.isEmpty)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.escape)
            }
            .padding()
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search history...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            Divider()
            
            // History List
            if filteredHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text(searchText.isEmpty ? "No processing history yet" : "No results found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Text("Process some text to see it appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredHistory, selection: $selectedRecord) { record in
                    HistoryRowView(record: record)
                        .tag(record)
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 800, height: 600)
        .sheet(item: $selectedRecord) { record in
            HistoryDetailView(record: record)
        }
    }
}

struct HistoryRowView: View {
    let record: ProcessingRecord
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with operation and time
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: record.operation.icon)
                        .foregroundColor(.blue)
                        .frame(width: 16)
                    
                    Text(record.operation.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeFormatter.string(from: record.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.2fs", record.processingTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Preview of input/output
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Input")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(record.input.prefix(100) + (record.input.count > 100 ? "..." : ""))
                        .font(.caption)
                        .lineLimit(2)
                        .padding(6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Output")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(record.output.prefix(100) + (record.output.count > 100 ? "..." : ""))
                        .font(.caption)
                        .lineLimit(2)
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Copy Input") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(record.input, forType: .string)
            }
            
            Button("Copy Output") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(record.output, forType: .string)
            }
            
            Divider()
            
            Button("View Details") {
                // This will be handled by the parent view
            }
        }
    }
}

struct HistoryDetailView: View {
    let record: ProcessingRecord
    @Environment(\.dismiss) private var dismiss
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: record.operation.icon)
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.operation.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(timeFormatter.string(from: record.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            
            // Processing info
            HStack {
                VStack(alignment: .leading) {
                    Text("Processing Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.3f seconds", record.processingTime))
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(record.input.count) → \(record.output.count)")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Input/Output
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Input Text")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(record.input, forType: .string)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    ScrollView {
                        Text(record.input)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Processed Result")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(record.output, forType: .string)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    ScrollView {
                        Text(record.output)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
        .frame(width: 800, height: 600)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
}
