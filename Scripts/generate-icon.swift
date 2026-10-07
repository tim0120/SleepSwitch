import AppKit
import Foundation

@main
struct GenerateIcon {
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

    @MainActor
    static func main() throws {
        let iconset = root.appendingPathComponent("build/AppIcon.iconset")
        try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
        for points in [16, 32, 128, 256, 512] {
            try render(size: points).write(to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
            try render(size: points * 2).write(to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
        }
        try render(size: 1024).write(to: root.appendingPathComponent("build/AppIcon-preview.png"))
        try render(size: 256).write(to: root.appendingPathComponent("Resources/AppIcon.png"))
        try menuPreview().write(to: root.appendingPathComponent("build/MenuIcon-preview.png"))
        print(iconset.path)
    }

    @MainActor
    static func bitmap(width: Int, height: Int) -> NSBitmapImageRep {
        NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                         isPlanar: false, colorSpaceName: .deviceRGB,
                         bytesPerRow: 0, bitsPerPixel: 0)!
    }

    @MainActor
    static func render(size: Int) throws -> Data {
        let bitmap = bitmap(width: size, height: size)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        defer { NSGraphicsContext.restoreGraphicsState() }
        let transform = AffineTransform(scale: CGFloat(size) / 1024)
        (transform as NSAffineTransform).concat()
        let tile = NSBezierPath(roundedRect: NSRect(x: 62, y: 62, width: 900, height: 900),
                                xRadius: 205, yRadius: 205)
        NSGradient(starting: NSColor(calibratedRed: 0.15, green: 0.20, blue: 0.28, alpha: 1),
                   ending: NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.15, alpha: 1))!
            .draw(in: tile, angle: -90)
        let mint = NSColor(calibratedRed: 0.67, green: 0.92, blue: 0.86, alpha: 1)
        SleepSwitchIcon.image(size: 774, blocked: true, color: mint, template: false)
            .draw(in: NSRect(x: 125, y: 125, width: 774, height: 774))
        return bitmap.representation(using: .png, properties: [:])!
    }

    @MainActor
    static func menuPreview() throws -> Data {
        let bitmap = bitmap(width: 720, height: 320)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: 720, height: 320).fill()
        let states: [(String, Bool, Bool)] = [("Normal", false, false), ("Blocked", true, false), ("Unknown", false, true)]
        for (index, state) in states.enumerated() {
            let x = CGFloat(index * 240)
            (state.0 as NSString).draw(at: CGPoint(x: x + 82, y: 270), withAttributes: [
                .font: NSFont.systemFont(ofSize: 18, weight: .medium), .foregroundColor: NSColor.black
            ])
            NSColor(calibratedRed: 0.13, green: 0.17, blue: 0.23, alpha: 1).setFill()
            NSRect(x: x + 20, y: 142, width: 200, height: 110).fill()
            for (color, y) in [(NSColor.white, CGFloat(158)), (NSColor.black, CGFloat(30))] {
                SleepSwitchIcon.image(size: 72, blocked: state.1, unknown: state.2, color: color, template: false)
                    .draw(in: NSRect(x: x + 60, y: y, width: 72, height: 72))
                SleepSwitchIcon.image(size: 18, blocked: state.1, unknown: state.2, color: color, template: false)
                    .draw(in: NSRect(x: x + 166, y: y + 27, width: 18, height: 18))
            }
        }
        return bitmap.representation(using: .png, properties: [:])!
    }
}
