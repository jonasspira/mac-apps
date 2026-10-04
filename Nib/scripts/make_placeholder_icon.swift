// Generates a placeholder Icon.png: deep ink-blue rounded square with a white
// fountain-pen nib. Usage: swift scripts/make_placeholder_icon.swift Icon.png
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// Background gradient (deep ink blue)
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let gradient = NSGradient(starting: NSColor(calibratedRed: 0.13, green: 0.24, blue: 0.55, alpha: 1),
                          ending: NSColor(calibratedRed: 0.06, green: 0.12, blue: 0.34, alpha: 1))!
gradient.draw(in: rect, angle: -70)

// Fountain pen nib (pointing down), in white
let nib = NSBezierPath()
let cx = size * 0.5
nib.move(to: NSPoint(x: cx, y: size * 0.14))                       // tip
nib.curve(to: NSPoint(x: cx - size * 0.19, y: size * 0.52),
          controlPoint1: NSPoint(x: cx - size * 0.06, y: size * 0.24),
          controlPoint2: NSPoint(x: cx - size * 0.19, y: size * 0.36))
nib.curve(to: NSPoint(x: cx, y: size * 0.86),
          controlPoint1: NSPoint(x: cx - size * 0.19, y: size * 0.72),
          controlPoint2: NSPoint(x: cx - size * 0.11, y: size * 0.86))
nib.curve(to: NSPoint(x: cx + size * 0.19, y: size * 0.52),
          controlPoint1: NSPoint(x: cx + size * 0.11, y: size * 0.86),
          controlPoint2: NSPoint(x: cx + size * 0.19, y: size * 0.72))
nib.curve(to: NSPoint(x: cx, y: size * 0.14),
          controlPoint1: NSPoint(x: cx + size * 0.19, y: size * 0.36),
          controlPoint2: NSPoint(x: cx + size * 0.06, y: size * 0.24))
nib.close()
NSColor.white.setFill()
nib.fill()

// Slit from tip up to the breather hole, in background blue
let ink = NSColor(calibratedRed: 0.09, green: 0.17, blue: 0.42, alpha: 1)
ink.setStroke()
let slit = NSBezierPath()
slit.lineWidth = 22
slit.lineCapStyle = .round
slit.move(to: NSPoint(x: cx, y: size * 0.17))
slit.line(to: NSPoint(x: cx, y: size * 0.55))
slit.stroke()

// Breather hole
ink.setFill()
let hole: CGFloat = 84
NSBezierPath(ovalIn: NSRect(x: cx - hole / 2, y: size * 0.55 - hole / 2,
                            width: hole, height: hole)).fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("could not render icon")
}
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Icon.png"
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
