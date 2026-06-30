// Renders the SpiraPaste app icon (Atlassian-blue squircle + stacked clipboard queue) to PNGs.
// Usage: swift make_icon.swift <output-dir>
import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func render(size: Int, scale: Int, name: String) {
    let px = size * scale
    let img = NSImage(size: NSSize(width: px, height: px))
    img.lockFocus()
    let u = CGFloat(px)
    let full = NSRect(x: 0, y: 0, width: px, height: px)

    // macOS-style rounded-square background with the Atlassian blue gradient
    // (Blue500 #2684FF → Blue700 #0C66E4).
    let margin = u * 0.09
    let squircle = roundedRect(full.insetBy(dx: margin, dy: margin), radius: u * 0.185)
    let bg = NSGradient(colors: [
        NSColor(calibratedRed: 0.149, green: 0.518, blue: 1.000, alpha: 1),
        NSColor(calibratedRed: 0.047, green: 0.400, blue: 0.894, alpha: 1),
    ])!
    bg.draw(in: squircle, angle: -90)

    // Two faded "queued" cards stacked behind, offset up-and-right.
    let cardW = u * 0.40, cardH = u * 0.50
    let baseX = u * 0.30, baseY = u * 0.24
    func card(_ dx: CGFloat, _ dy: CGFloat, alpha: CGFloat) {
        let r = NSRect(x: baseX + dx, y: baseY + dy, width: cardW, height: cardH)
        NSColor(white: 1, alpha: alpha).setFill()
        roundedRect(r, radius: u * 0.045).fill()
    }
    card(u * 0.10, u * 0.10, alpha: 0.35)
    card(u * 0.05, u * 0.05, alpha: 0.60)

    // Front clipboard card (solid white).
    let front = NSRect(x: baseX, y: baseY, width: cardW, height: cardH)
    NSColor.white.setFill()
    roundedRect(front, radius: u * 0.05).fill()

    // Clip at the top of the front card.
    let clipW = cardW * 0.42, clipH = u * 0.06
    let clip = NSRect(x: front.midX - clipW / 2, y: front.maxY - clipH * 0.55,
                      width: clipW, height: clipH)
    NSColor(calibratedRed: 0.000, green: 0.333, blue: 0.800, alpha: 1).setFill()
    roundedRect(clip, radius: clipH * 0.5).fill()

    // Three "lines of text" on the front card.
    let lineColor = NSColor(calibratedRed: 0.000, green: 0.333, blue: 0.800, alpha: 1)
    lineColor.setFill()
    for (i, frac) in [0.62, 0.45, 0.28].enumerated() {
        let w = cardW * (i == 2 ? 0.45 : 0.66)
        let r = NSRect(x: front.minX + cardW * 0.17,
                       y: front.minY + cardH * CGFloat(frac),
                       width: w, height: u * 0.035)
        roundedRect(r, radius: u * 0.02).fill()
    }

    img.unlockFocus()

    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
}

for (size, scale) in [(16,1),(16,2),(32,1),(32,2),(128,1),(128,2),(256,1),(256,2),(512,1),(512,2)] {
    let name = scale == 1 ? "icon_\(size)x\(size)" : "icon_\(size)x\(size)@2x"
    render(size: size, scale: scale, name: name)
}
print("Icon PNGs written to \(outDir)")
