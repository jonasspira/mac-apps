// Renders the Pasties app icon by placing Icon.png into the macOS icon grid:
// centered at ~80% size with transparent margin, so it sits at the same
// footprint as other macOS app icons (instead of full-bleed).
// Usage: swift make_icon.swift <source-png> <output-iconset-dir>
import AppKit

let args = CommandLine.arguments
let srcPath = args.count > 1 ? args[1] : "Icon.png"
let outDir  = args.count > 2 ? args[2] : "icon.iconset"

guard let src = NSImage(contentsOfFile: srcPath) else {
    FileHandle.standardError.write("cannot load \(srcPath)\n".data(using: .utf8)!)
    exit(1)
}
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func render(px: Int, name: String) {
    let img = NSImage(size: NSSize(width: px, height: px))
    img.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    // macOS icon grid: live area ≈ 80% of the canvas, centered (~10% margin).
    let margin = CGFloat(px) * 0.10
    let body = NSRect(x: margin, y: margin,
                      width: CGFloat(px) - 2 * margin,
                      height: CGFloat(px) - 2 * margin)
    src.draw(in: body, from: .zero, operation: .sourceOver, fraction: 1.0)
    img.unlockFocus()

    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
}

let sizes: [(Int, String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]
for (px, name) in sizes { render(px: px, name: name) }
print("Icon rendered from \(srcPath) → \(outDir)")
