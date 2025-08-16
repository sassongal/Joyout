#!/usr/bin/env python3

"""
JoyaaS Real Logo Icon Generator
Generates all required macOS app icon sizes from your actual logoflatupdated.png logo
"""

from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import os
import sys

# Path to your actual logo
LOGO_PATH = "/Users/galsasson/Downloads/Joyout/logoflatupdated.png"

def load_and_process_logo():
    """Load and prepare the actual logo for processing"""
    try:
        # Load your actual logo
        logo = Image.open(LOGO_PATH)
        print(f"📸 Loaded logo: {logo.size[0]}x{logo.size[1]} pixels")
        
        # Ensure it has an alpha channel
        if logo.mode != 'RGBA':
            logo = logo.convert('RGBA')
        
        return logo
    except FileNotFoundError:
        print(f"❌ Logo file not found at: {LOGO_PATH}")
        print("Please ensure logoflatupdated.png exists in the project root.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error loading logo: {e}")
        sys.exit(1)

def create_icon_from_logo(size, logo):
    """Create an icon of specified size from your actual logo"""
    
    # Create a square canvas with transparent background
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # Calculate the size to fit the logo while maintaining aspect ratio
    logo_size = min(size, size)
    
    # Resize the logo to fit the canvas with high quality
    resized_logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    
    # Calculate position to center the logo
    x = (size - logo_size) // 2
    y = (size - logo_size) // 2
    
    # Paste the logo onto the canvas
    canvas.paste(resized_logo, (x, y), resized_logo)
    
    # Apply size-specific optimizations
    if size <= 32:
        # For small sizes (menu bar), enhance contrast and sharpness
        canvas = enhance_for_small_size(canvas)
    elif size >= 512:
        # For large sizes, ensure smooth edges
        canvas = enhance_for_large_size(canvas)
    
    return canvas

def enhance_for_small_size(img):
    """Enhance image for small sizes (menu bar icons)"""
    # Increase contrast for better visibility at small sizes
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(1.3)
    
    # Increase sharpness
    enhancer = ImageEnhance.Sharpness(img)
    img = enhancer.enhance(1.2)
    
    return img

def enhance_for_large_size(img):
    """Enhance image for large sizes"""
    # Apply subtle smoothing for large sizes
    return img.filter(ImageFilter.SMOOTH_MORE)

def create_menubar_icon(logo):
    """Create a special black/white version optimized for the menu bar"""
    size = 18  # Standard menu bar icon size
    
    # Start with the regular icon
    icon = create_icon_from_logo(size, logo)
    
    # For menu bar, we need a high-contrast version
    # Convert to grayscale first
    gray = icon.convert('L')
    
    # Create a new RGBA image
    menubar_icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # Convert grayscale to black/white with alpha
    pixels = gray.load()
    new_pixels = menubar_icon.load()
    
    for y in range(size):
        for x in range(size):
            gray_val = pixels[x, y]
            alpha = icon.getpixel((x, y))[3] if icon.mode == 'RGBA' else 255
            
            # Create black icon with preserved alpha
            if gray_val < 128 and alpha > 128:  # If dark enough and not transparent
                new_pixels[x, y] = (0, 0, 0, 255)  # Black
            else:
                new_pixels[x, y] = (0, 0, 0, 0)  # Transparent
    
    return menubar_icon

def generate_all_icons():
    """Generate all required icon sizes from your actual logo"""
    
    # Load your actual logo first
    logo = load_and_process_logo()
    
    # Required sizes for macOS apps
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    
    assets_dir = "/Users/galsasson/Downloads/Joyout/JoyaaS-MenuBar/JoyaaSMenuBar/Assets.xcassets/AppIcon.appiconset"
    
    # Ensure directory exists
    os.makedirs(assets_dir, exist_ok=True)
    
    print("🦚 Generating JoyaaS Icons from your REAL logo...")
    print(f"📁 Output directory: {assets_dir}")
    
    for size in sizes:
        print(f"🎨 Creating {size}x{size} icon from your logo...")
        
        # Use the real logo to create the icon
        icon = create_icon_from_logo(size, logo)
        output_path = os.path.join(assets_dir, f"peacock-{size}.png")
        
        # Save with high quality
        icon.save(output_path, "PNG", optimize=True, dpi=(144, 144))
        print(f"✅ Saved: peacock-{size}.png")
    
    # Create a special menu bar version optimized for menu bar visibility
    print("🔲 Creating menu bar version from your logo...")
    menubar_icon = create_menubar_icon(logo)
    menubar_path = "/Users/galsasson/Downloads/Joyout/JoyaaS-MenuBar/JoyaaSMenuBar/menubar-icon.png"
    menubar_icon.save(menubar_path, "PNG", optimize=True)
    print(f"✅ Saved: menubar-icon.png")
    
    # Also create installer/DMG versions
    print("💿 Creating installer icons...")
    
    # Create 512px version for installer background
    installer_icon = create_icon_from_logo(512, logo)
    installer_path = "/Users/galsasson/Downloads/Joyout/JoyaaS-MenuBar/installer-logo-512.png"
    installer_icon.save(installer_path, "PNG", optimize=True, dpi=(144, 144))
    print(f"✅ Saved: installer-logo-512.png")
    
    # Create 256px version for general use
    general_icon = create_icon_from_logo(256, logo)
    general_path = "/Users/galsasson/Downloads/Joyout/JoyaaS-MenuBar/logo-256.png"
    general_icon.save(general_path, "PNG", optimize=True)
    print(f"✅ Saved: logo-256.png")
    
    print("\n🎉 All icons generated successfully from your REAL logo!")
    print("Your beautiful logoflatupdated.png is now properly integrated into the app!")


if __name__ == "__main__":
    try:
        generate_all_icons()
    except ImportError:
        print("❌ PIL (Pillow) not found. Installing...")
        os.system("pip3 install Pillow")
        generate_all_icons()
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
