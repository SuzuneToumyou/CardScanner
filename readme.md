# CardScanner (macOS)

An intuitive, lightweight macOS desktop application built with **SwiftUI** and **Apple Vision Framework**. It automatically detects, deskews (perspective-corrects), crops, and vertically merges two card images (such as driver's licenses, ID cards, or membership badges) into a single combined image.

![macOS](https://img.shields.io/badge/OS-macOS%2011.0%2B-blue)
![Swift](https://img.shields.io/badge/Language-Swift-orange)
![License](https://img.shields.io/badge/License-GPL--3.0-green)

---

## Features

- 🔍 **Automatic Rectangle Detection**: Powered by Apple's Vision framework (`VNDetectRectanglesRequest`) to quickly detect card contours.
- 📐 **Perspective Correction**: Straightens slanted images using Core Image filters (`CIPerspectiveCorrection`).
- 🔄 **Auto-Orientation**: Automatically shifts and rotates card images to horizontal orientation if needed.
- 🎚️ **Individual Margin Sliders**: Fine-tune edge cropping independently for top and bottom images (from -30px to +30px) to seamlessly eliminate dark borders.
- 🖼️ **Live Interactive Preview**: Instant side-by-side preview that updates in real-time as you adjust sliders.
- 🔍 **Click-to-Zoom Modal**: Click on the preview image to expand and view high-resolution details in a modal window.
- 💾 **PNG & JPEG Export**: Supports saving high-quality output images in either `.png` or `.jpg` formats.
- 🖥️ **Native SwiftUI Interface**: Responsive window resizing and dark/light mode support without external dependencies.

---

## How to Use

1. Click **Browse** to select **Image 1 (Top)** and **Image 2 (Bottom)**.
2. Select your desired **Save Output Path**.
3. Adjust the edge-cropping sliders for Image 1 and Image 2 until any remaining border artifacts disappear from the live preview.
4. Click **Save Combined Image**.

---

## System Requirements

- **Operating System**: macOS 11.0 (Big Sur) or later
- **Compiler**: Xcode Command Line Tools (`swiftc`) or Xcode 12+

---

## Building from Source

You can easily compile the application into a standalone `.app` bundle via Terminal:

```bash
# 1. Compile Swift source code
swiftc -parse-as-library App.swift -o CardScannerBinary \
  -framework SwiftUI -framework Vision -framework CoreImage -framework AppKit

# 2. Setup App Bundle Directory Structure
mkdir -p "CardScanner.app/Contents/MacOS"
mkdir -p "CardScanner.app/Contents/Resources"
mv CardScannerBinary "CardScanner.app/Contents/MacOS/CardScanner"

# 3. Generate Info.plist
cat << 'EOF' > "CardScanner.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CardScanner</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.CardScanner</string>
    <key>CFBundleName</key>
    <string>CardScanner</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
```

Double-click `CardScanner.app` to launch the program.

---

## Technologies Used

- **Framework**: SwiftUI (App Architecture)
- **Computer Vision**: Apple Vision Framework (`VNDetectRectanglesRequest`)
- **Image Manipulation**: Core Image (`CIPerspectiveCorrection`, `CIContext`)
- **Native macOS Interoperability**: AppKit (`NSImage`, `NSOpenPanel`, `NSSavePanel`)

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**.  
See the [LICENSE](LICENSE) file for full license text.
