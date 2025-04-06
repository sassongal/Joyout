import SwiftUI

struct AppearanceSettings: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(NSLocalizedString("Appearance", comment: ""))
                .font(.headline)
                .padding(.bottom, 5)
            
            Picker("", selection: $appearanceMode) {
                Text(NSLocalizedString("System", comment: "")).tag(AppearanceMode.system)
                Text(NSLocalizedString("Light", comment: "")).tag(AppearanceMode.light)
                Text(NSLocalizedString("Dark", comment: "")).tag(AppearanceMode.dark)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: appearanceMode) { newValue in
                applyAppearanceMode(newValue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func applyAppearanceMode(_ mode: AppearanceMode) {
        // In a real app, this would use AppKit to set the appearance
        // For demonstration purposes, we'll just print the change
        print("Appearance mode changed to: \(mode)")
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    
    var id: String { self.rawValue }
}

struct AppearanceSettings_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSettings()
    }
}
