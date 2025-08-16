import Foundation
import AppKit
import SwiftUI

class FontManager: ObservableObject {
    static let shared = FontManager()
    
    @Published var availableFonts: [CustomFont] = []
    @Published var selectedFontName: String = "System Default"
    @Published var selectedFontSize: Double = 14.0
    
    struct CustomFont: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let displayName: String
        let familyName: String
        let weight: String
        let isSystemFont: Bool
        let fontPath: String?
        
        var nsFont: NSFont? {
            if isSystemFont {
                return NSFont.systemFont(ofSize: 14.0)
            } else if let path = fontPath {
                return NSFont(name: name, size: 14.0)
            }
            return nil
        }
        
        static func == (lhs: CustomFont, rhs: CustomFont) -> Bool {
            return lhs.name == rhs.name
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }
    
    private init() {
        loadSystemFonts()
        loadCustomFonts()
        loadPreferences()
    }
    
    private func loadSystemFonts() {
        // Add system fonts
        availableFonts.append(CustomFont(
            name: "System Default",
            displayName: "System Default",
            familyName: "System",
            weight: "Regular",
            isSystemFont: true,
            fontPath: nil
        ))
        
        availableFonts.append(CustomFont(
            name: "SF Mono",
            displayName: "SF Mono (System Monospace)",
            familyName: "SF Mono",
            weight: "Regular",
            isSystemFont: true,
            fontPath: nil
        ))
        
        // Add Hebrew-friendly system fonts
        let hebrewSystemFonts = [
            "Arial Hebrew",
            "Times New Roman",
            "Arial Unicode MS",
            "Lucida Grande"
        ]
        
        for fontName in hebrewSystemFonts {
            if NSFont(name: fontName, size: 14.0) != nil {
                availableFonts.append(CustomFont(
                    name: fontName,
                    displayName: fontName,
                    familyName: fontName,
                    weight: "Regular",
                    isSystemFont: true,
                    fontPath: nil
                ))
            }
        }
    }
    
    private func loadCustomFonts() {
        let fontsPath = "/Users/galsasson/Downloads/Joyout/fonts"
        
        guard let enumerator = FileManager.default.enumerator(atPath: fontsPath) else {
            print("⚠️ Could not access fonts directory at: \(fontsPath)")
            return
        }
        
        var registeredFonts = 0
        
        while let fileName = enumerator.nextObject() as? String {
            let filePath = "\(fontsPath)/\(fileName)"
            let fileURL = URL(fileURLWithPath: filePath)
            
            // Check if it's a font file
            let fontExtensions = ["ttf", "otf", "ttc"]
            guard fontExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }
            
            // Register the font
            if let fontDataProvider = CGDataProvider(url: fileURL as CFURL),
               let cgFont = CGFont(fontDataProvider) {
                
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                    
                    if let fontName = cgFont.postScriptName as String? {
                        let displayName = parseDisplayName(from: fileName, fontName: fontName)
                        let familyName = parseFamilyName(from: fontName)
                        let weight = parseWeight(from: fileName, fontName: fontName)
                        
                        let customFont = CustomFont(
                            name: fontName,
                            displayName: displayName,
                            familyName: familyName,
                            weight: weight,
                            isSystemFont: false,
                            fontPath: filePath
                        )
                        
                        availableFonts.append(customFont)
                        registeredFonts += 1
                        print("✅ Registered font: \(displayName)")
                    }
                } else {
                    if let error = error?.takeRetainedValue() {
                        print("❌ Failed to register font \(fileName): \(error)")
                    }
                }
            }
        }
        
        print("📚 Successfully registered \(registeredFonts) custom fonts")
        
        // Sort fonts alphabetically
        availableFonts.sort { $0.displayName < $1.displayName }
    }
    
    private func parseDisplayName(from fileName: String, fontName: String) -> String {
        // Clean up the filename for display
        var name = fileName
        
        // Remove file extension
        if let dotIndex = name.lastIndex(of: ".") {
            name = String(name[..<dotIndex])
        }
        
        // Replace underscores and hyphens with spaces
        name = name.replacingOccurrences(of: "_", with: " ")
        name = name.replacingOccurrences(of: "-", with: " ")
        
        // Capitalize words
        name = name.split(separator: " ")
            .map { String($0).capitalized }
            .joined(separator: " ")
        
        return name
    }
    
    private func parseFamilyName(from fontName: String) -> String {
        // Extract family name (usually the first part before a hyphen)
        if let hyphenIndex = fontName.firstIndex(of: "-") {
            return String(fontName[..<hyphenIndex])
        }
        return fontName
    }
    
    private func parseWeight(from fileName: String, fontName: String) -> String {
        let weights = [
            "Thin", "ExtraLight", "Light", "Regular", "Medium", 
            "SemiBold", "Bold", "ExtraBold", "Black", "Heavy"
        ]
        
        let searchText = fileName + " " + fontName
        
        for weight in weights {
            if searchText.localizedCaseInsensitiveContains(weight) {
                return weight
            }
        }
        
        return "Regular"
    }
    
    func getFont(size: CGFloat = 14.0) -> NSFont {
        if selectedFontName == "System Default" {
            return NSFont.systemFont(ofSize: size)
        }
        
        if let customFont = availableFonts.first(where: { $0.name == selectedFontName }) {
            if customFont.isSystemFont {
                if customFont.name == "SF Mono" {
                    return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
                } else if let systemFont = NSFont(name: customFont.name, size: size) {
                    return systemFont
                }
            } else if let font = NSFont(name: customFont.name, size: size) {
                return font
            }
        }
        
        // Fallback to system font
        return NSFont.systemFont(ofSize: size)
    }
    
    func getSwiftUIFont(size: CGFloat = 14.0) -> Font {
        if selectedFontName == "System Default" {
            return .system(size: size)
        }
        
        if let customFont = availableFonts.first(where: { $0.name == selectedFontName }) {
            if customFont.isSystemFont {
                if customFont.name == "SF Mono" {
                    return .system(size: size, design: .monospaced)
                } else {
                    return .custom(customFont.name, size: size)
                }
            } else {
                return .custom(customFont.name, size: size)
            }
        }
        
        // Fallback to system font
        return .system(size: size)
    }
    
    func setSelectedFont(_ fontName: String) {
        selectedFontName = fontName
        savePreferences()
        print("🎨 Font changed to: \(fontName)")
    }
    
    func setFontSize(_ size: Double) {
        selectedFontSize = size
        savePreferences()
        print("📏 Font size changed to: \(size)")
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(selectedFontName, forKey: "selectedFontName")
        UserDefaults.standard.set(selectedFontSize, forKey: "selectedFontSize")
    }
    
    private func loadPreferences() {
        selectedFontName = UserDefaults.standard.string(forKey: "selectedFontName") ?? "System Default"
        selectedFontSize = UserDefaults.standard.double(forKey: "selectedFontSize")
        
        // Set default font size if not previously set
        if selectedFontSize == 0 {
            selectedFontSize = 14.0
        }
    }
    
    func getFontPreview(for fontName: String) -> String {
        // Hebrew and English preview text
        return "שלום Hello 123 אבג ABC"
    }
    
    func getRecommendedFonts() -> [CustomFont] {
        // Return fonts that are particularly good for Hebrew/English text
        return availableFonts.filter { font in
            font.name.localizedCaseInsensitiveContains("hebrew") ||
            font.name.localizedCaseInsensitiveContains("noto") ||
            font.name == "System Default" ||
            font.name == "Arial Unicode MS"
        }
    }
}
