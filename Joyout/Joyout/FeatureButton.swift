import SwiftUI


struct FeatureButton: View {
    var title: String
    var shortcut: String
    var imageAsset: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(imageAsset)
                    .resizable()
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                if !shortcut.isEmpty {
                    Text(shortcut)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
