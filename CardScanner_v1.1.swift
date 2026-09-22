import SwiftUI
import Vision
import CoreImage
import AppKit

struct CardScanner {
    
    static func processSingleImage(inputURL: URL, cropPixels: CGFloat) -> CIImage? {
        guard let ciImage = CIImage(contentsOf: inputURL) else { return nil }
        
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        let request = VNDetectRectanglesRequest()
        request.minimumConfidence = 0.6
        request.maximumObservations = 1
        
        do {
            try requestHandler.perform([request])
        } catch {
            return nil
        }
        
        guard let results = request.results, let rectangle = results.first else {
            return nil
        }
        
        let imageSize = ciImage.extent.size
        
        let topLeft = CGPoint(x: rectangle.topLeft.x * imageSize.width, y: rectangle.topLeft.y * imageSize.height)
        let topRight = CGPoint(x: rectangle.topRight.x * imageSize.width, y: rectangle.topRight.y * imageSize.height)
        let bottomLeft = CGPoint(x: rectangle.bottomLeft.x * imageSize.width, y: rectangle.bottomLeft.y * imageSize.height)
        let bottomRight = CGPoint(x: rectangle.bottomRight.x * imageSize.width, y: rectangle.bottomRight.y * imageSize.height)
        
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        filter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
        
        guard var outputImage = filter.outputImage else { return nil }
        
        if outputImage.extent.width < outputImage.extent.height {
            outputImage = outputImage.oriented(.left)
        }
        
        let basePixels: CGFloat = 18.0
        let totalCrop = max(0, basePixels + cropPixels)
        let rect = outputImage.extent
        
        if rect.width > totalCrop * 2 && rect.height > totalCrop * 2 {
            let croppedRect = CGRect(
                x: rect.origin.x + totalCrop,
                y: rect.origin.y + totalCrop,
                width: rect.width - (totalCrop * 2),
                height: rect.height - (totalCrop * 2)
            )
            outputImage = outputImage.cropped(to: croppedRect)
        }
        
        return outputImage
    }
    
    static func combineImages(ciImg1: CIImage, ciImg2: CIImage) -> NSImage? {
        let context = CIContext()
        guard let cgImg1 = context.createCGImage(ciImg1, from: ciImg1.extent),
              let cgImg2 = context.createCGImage(ciImg2, from: ciImg2.extent) else {
            return nil
        }
        
        let maxWidth = max(cgImg1.width, cgImg2.width)
        let scale1 = CGFloat(maxWidth) / CGFloat(cgImg1.width)
        let scale2 = CGFloat(maxWidth) / CGFloat(cgImg2.width)
        
        let height1 = Int(CGFloat(cgImg1.height) * scale1)
        let height2 = Int(CGFloat(cgImg2.height) * scale2)
        let totalHeight = height1 + height2
        
        guard let colorSpace = cgImg1.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context2D = CGContext(
                data: nil,
                width: maxWidth,
                height: totalHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }
        
        context2D.draw(cgImg1, in: CGRect(x: 0, y: height2, width: maxWidth, height: height1))
        context2D.draw(cgImg2, in: CGRect(x: 0, y: 0, width: maxWidth, height: height2))
        
        guard let combinedCGImage = context2D.makeImage() else { return nil }
        return NSImage(cgImage: combinedCGImage, size: NSSize(width: maxWidth, height: totalHeight))
    }
}

struct ZoomView: View {
    let image: NSImage
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("閉じる") { presentationMode.wrappedValue.dismiss() }
                .padding()
            }
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .padding()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct ContentView: View {
    @State private var inputPath1: String = ""
    @State private var inputPath2: String = ""
    @State private var outputPath: String = ""
    
    @State private var cropPixels1: Double = -10.0
    @State private var cropPixels2: Double = -10.0
    
    @State private var previewImage: NSImage? = nil
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showZoomSheet: Bool = false

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 14) {
                Group {
                    HStack {
                        Text("画像 1 (上):").frame(width: 80, alignment: .trailing)
                        TextField("", text: $inputPath1).textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("参照") { selectInputFile { inputPath1 = $0; updatePreview() } }
                    }
                    
                    HStack {
                        Text("画像 2 (下):").frame(width: 80, alignment: .trailing)
                        TextField("", text: $inputPath2).textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("参照") { selectInputFile { inputPath2 = $0; updatePreview() } }
                    }
                    
                    HStack {
                        Text("保存先:").frame(width: 80, alignment: .trailing)
                        TextField("", text: $outputPath).textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("参照") { selectOutputFile() }
                    }
                }
                
                Divider()
                
                VStack(spacing: 4) {
                    HStack {
                        Text("画像1 縁の削り調整:")
                        Spacer()
                        Text("\(Int(cropPixels1) >= 0 ? "+\(Int(cropPixels1))" : "\(Int(cropPixels1))") px").bold().monospacedDigit()
                    }
                    Slider(value: $cropPixels1, in: -30...30, step: 1) { _ in updatePreview() }
                }
                
                VStack(spacing: 4) {
                    HStack {
                        Text("画像2 縁の削り調整:")
                        Spacer()
                        Text("\(Int(cropPixels2) >= 0 ? "+\(Int(cropPixels2))" : "\(Int(cropPixels2))") px").bold().monospacedDigit()
                    }
                    Slider(value: $cropPixels2, in: -30...30, step: 1) { _ in updatePreview() }
                }
                
                Spacer()
                
                Button("結合画像を保存") { saveCombinedImage() }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .frame(width: 340)
            
            Divider()
            
            VStack {
                HStack {
                    Text("プレビュー").font(.caption).foregroundColor(.gray)
                    Spacer()
                    if previewImage != nil {
                        Text("🔍 クリックで拡大表示").font(.caption).foregroundColor(.blue)
                    }
                }
                
                ZStack {
                    Color(NSColor.controlBackgroundColor)
                    if let img = previewImage {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                            .onTapGesture { showZoomSheet = true }
                    } else {
                        Text("画像を選択するとプレビューが表示されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(16)
        .frame(minWidth: 800, minHeight: 450)
        .sheet(isPresented: $showZoomSheet) {
            if let img = previewImage {
                ZoomView(image: img)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("通知"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func updatePreview() {
        guard !inputPath1.isEmpty, !inputPath2.isEmpty else { return }
        
        let url1 = URL(fileURLWithPath: inputPath1)
        let url2 = URL(fileURLWithPath: inputPath2)
        
        guard let ci1 = CardScanner.processSingleImage(inputURL: url1, cropPixels: CGFloat(cropPixels1)),
              let ci2 = CardScanner.processSingleImage(inputURL: url2, cropPixels: CGFloat(cropPixels2)) else {
            return
        }
        
        previewImage = CardScanner.combineImages(ciImg1: ci1, ciImg2: ci2)
    }

    private func selectInputFile(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url { completion(url.path) }
    }

    private func selectOutputFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.nameFieldStringValue = "combined_output.png"
        if panel.runModal() == .OK, let url = panel.url { outputPath = url.path }
    }

    private func saveCombinedImage() {
        guard let img = previewImage, !outputPath.isEmpty else {
            alertMessage = "画像と保存先を選択してください"
            showAlert = true
            return
        }
        
        guard let tiffData = img.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            alertMessage = "画像の変換に失敗しました"
            showAlert = true
            return
        }
        
        let isJpg = outputPath.lowercased().hasSuffix(".jpg") || outputPath.lowercased().hasSuffix(".jpeg")
        let fileType: NSBitmapImageRep.FileType = isJpg ? .jpeg : .png
        guard let data = bitmapRep.representation(using: fileType, properties: [:]) else { return }
        
        do {
            try data.write(to: URL(fileURLWithPath: outputPath))
            alertMessage = "保存が完了しました！"
            showAlert = true
        } catch {
            alertMessage = "保存中にエラーが発生しました"
            showAlert = true
        }
    }
}

@main
struct CardScannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}