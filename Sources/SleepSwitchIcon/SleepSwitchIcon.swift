import AppKit

/// The shared vector mark for the menu bar, app bundle, and repository artwork.
/// Coordinates use a 100-point canvas, so every size has the same silhouette.
public enum SleepSwitchIcon {
    public static func image(
        size: CGFloat,
        blocked: Bool,
        unknown: Bool = false,
        color: NSColor = .white,
        template: Bool = true
    ) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            defer { context.restoreGState() }
            context.translateBy(x: rect.minX, y: rect.minY)
            context.scaleBy(x: rect.width / 100, y: rect.height / 100)
            context.setFillColor(color.cgColor)
            context.setStrokeColor(color.cgColor)

            // Equal-radius intersecting circles make a continuous crescent with
            // exact meeting points, rather than joined, overlapping outlines.
            let radius: CGFloat = 35
            let angle = acos(10 / radius)
            let moon = CGMutablePath()
            // Center the crescent's visible bounds, not the circle it comes from.
            // Its horizontal bounds are 27.5...72.5 in every sleep state.
            moon.addArc(center: CGPoint(x: 62.5, y: 50), radius: radius,
                        startAngle: angle, endAngle: 2 * .pi - angle, clockwise: false)
            moon.addArc(center: CGPoint(x: 82.5, y: 50), radius: radius,
                        startAngle: .pi + angle, endAngle: .pi - angle, clockwise: true)
            moon.closeSubpath()

            let slash = CGMutablePath()
            slash.move(to: CGPoint(x: 21, y: 18))
            slash.addLine(to: CGPoint(x: 81, y: 82))

            context.saveGState()
            if blocked {
                // Leave a small transparent gap around the slash. Clip instead
                // of clearing pixels, so the app-icon background stays intact.
                let cutout = slash.copy(strokingWithWidth: 15.5, lineCap: .round,
                                        lineJoin: .round, miterLimit: 1)
                let clip = CGMutablePath()
                clip.addRect(CGRect(x: 0, y: 0, width: 100, height: 100))
                clip.addPath(cutout)
                context.addPath(clip)
                context.clip(using: .evenOdd)
            }
            context.addPath(moon)
            context.fillPath()
            context.restoreGState()

            if blocked {
                context.setLineWidth(8.5)
                context.setLineCap(.round)
                context.addPath(slash)
                context.strokePath()
            }
            if unknown {
                context.fillEllipse(in: CGRect(x: 80, y: 11, width: 8, height: 8))
            }
            return true
        }
        image.isTemplate = template
        return image
    }
}
