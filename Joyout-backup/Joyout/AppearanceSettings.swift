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
            .onChange(of: appearanceMode) { oldValue, newValue in
                applyAppearanceMode(newValue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func applyAppearanceMode(_ mode: AppearanceMode) {
        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
        print("Appearance mode changed to: \(mode)")
    }

}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { self.rawValue }
}
