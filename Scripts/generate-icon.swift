import AppKit
import Foundation

// Native drawing keeps the icon editable and reproducible without external assets.
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func render(size: Int) throws -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB,
                                  bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    defer { NSGraphicsContext.restoreGraphicsState() }
    let scale = CGFloat(size) / 1024
    let transform = AffineTransform(scale: scale)
    (transform as NSAffineTransform).concat()
    let tile = NSBezierPath(roundedRect: NSRect(x: 62, y: 62, width: 900, height: 900),
                            xRadius: 205, yRadius: 205)
    NSGradient(starting: NSColor(calibratedRed: 0.15, green: 0.20, blue: 0.28, alpha: 1),
               ending: NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.15, alpha: 1))!
        .draw(in: tile, angle: -90)

    let moon = NSBezierPath()
    let angle = acos(75.0 / 250.0) * 180 / Double.pi
    moon.appendArc(withCenter: CGPoint(x: 510, y: 512), radius: 250,
                   startAngle: angle, endAngle: 360 - angle, clockwise: false)
    moon.appendArc(withCenter: CGPoint(x: 660, y: 512), radius: 250,
                   startAngle: 180 + angle, endAngle: 180 - angle, clockwise: true)
    moon.close()
    moon.lineWidth = 38
    moon.lineJoinStyle = .round
    NSColor(calibratedRed: 0.67, green: 0.92, blue: 0.86, alpha: 1).setStroke()
    moon.stroke()
    let slash = NSBezierPath()
    slash.move(to: CGPoint(x: 290, y: 292))
    slash.line(to: CGPoint(x: 720, y: 722))
    slash.lineWidth = 54
    slash.lineCapStyle = .round
    slash.stroke()
    return bitmap.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    try render(size: points).write(to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    try render(size: points * 2).write(to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
try render(size: 1024).write(to: root.appendingPathComponent("build/AppIcon-preview.png"))
try render(size: 256).write(to: root.appendingPathComponent("Resources/AppIcon.png"))
print(iconset.path)
