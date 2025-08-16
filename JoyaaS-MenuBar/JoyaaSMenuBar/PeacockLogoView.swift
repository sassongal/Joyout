import SwiftUI

struct PeacockLogoView: View {
    let size: CGFloat
    var customColor: Color? = nil
    
    private var logoBlue: Color {
        Color(red: 5.0/255.0, green: 71.0/255.0, blue: 179.0/255.0) // Your actual logo blue #0547B3
    }
    
    private var logoBlack: Color {
        Color(red: 10.0/255.0, green: 16.0/255.0, blue: 20.0/255.0) // Your actual logo dark #0A1014
    }
    
    var body: some View {
        ZStack {
            // Main peacock body (blue)
            Ellipse()
                .fill(customColor ?? logoBlue)
                .frame(width: size * 0.7, height: size * 0.8)
                .offset(x: size * 0.05, y: size * 0.1)
            
            // Eye/head area (black curved section)
            Ellipse()
                .fill(logoBlack)
                .frame(width: size * 0.25, height: size * 0.4)
                .offset(x: -size * 0.15, y: size * 0.05)
            
            // Beak
            Path { path in
                path.move(to: CGPoint(x: -size * 0.3, y: size * 0.1))
                path.addLine(to: CGPoint(x: -size * 0.4, y: size * 0.15))
                path.addLine(to: CGPoint(x: -size * 0.3, y: size * 0.2))
                path.closeSubpath()
            }
            .fill(logoBlack)
            
            // Crown feathers (three dots with stems)
            ForEach(0..<3, id: \.self) { index in
                let xOffset = (CGFloat(index) - 1) * size * 0.15
                let yOffset = index == 1 ? -size * 0.4 : -size * 0.35
                
                // Feather stem
                Rectangle()
                    .fill(logoBlack)
                    .frame(width: 1.5, height: size * 0.2)
                    .offset(x: xOffset * 0.7, y: -size * 0.25)
                
                // Feather tip
                Circle()
                    .fill(logoBlack)
                    .frame(width: size * 0.1, height: size * 0.1)
                    .offset(x: xOffset, y: yOffset)
            }
            
            // Eye highlight (for larger sizes)
            if size >= 16 {
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.06, height: size * 0.06)
                    .offset(x: -size * 0.12, y: -size * 0.02)
            }
        }
        .frame(width: size, height: size)
    }
}

// Extension for easier use with different styling
extension PeacockLogoView {
    func peacockBlue() -> some View {
        self
    }
    
    func peacockGreen() -> some View {
        PeacockLogoView(size: size, customColor: .green)
    }
    
    func peacockGray() -> some View {
        PeacockLogoView(size: size, customColor: .gray)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            PeacockLogoView(size: 16)
            PeacockLogoView(size: 24)
            PeacockLogoView(size: 32)
            PeacockLogoView(size: 48)
        }
        
        HStack(spacing: 20) {
            PeacockLogoView(size: 32).peacockGreen()
            PeacockLogoView(size: 32).peacockGray()
            PeacockLogoView(size: 32, customColor: .red)
        }
    }
    .padding()
}
