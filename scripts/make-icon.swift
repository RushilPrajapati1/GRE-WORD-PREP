// Renders the app icon (two drill option cards, one picked correctly) using the
// design's colors and the bundled Newsreader font.
// Usage: swift scripts/make-icon.swift
import AppKit
import CoreText

let fontDir = "GREWordGroups/Resources/Fonts"
let output = "GREWordGroups/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let size: CGFloat = 1024

CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: "\(fontDir)/Newsreader-Medium.ttf") as CFURL, .process, nil)

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let accent = color(0x2F43B8), ink = color(0x1A1916)
let success = color(0x1F7A4D), successSoft = color(0xE3F2EA), successInk = color(0x145535)
let serif = NSFont(name: "Newsreader-Medium", size: 150)!

func card(_ rect: CGRect, fill: NSColor, stroke: NSColor? = nil) {
    let path = NSBezierPath(roundedRect: rect, xRadius: 58, yRadius: 58)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = 16
        path.stroke()
    }
}

func word(_ text: String, color: NSColor, center: CGPoint) {
    let string = NSAttributedString(string: text, attributes: [.font: serif, .foregroundColor: color])
    let bounds = string.size()
    string.draw(at: CGPoint(x: center.x - bounds.width / 2, y: center.y - bounds.height / 2))
}

func checkBadge(center: CGPoint, radius: CGFloat) {
    success.setFill()
    NSBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
    let tick = NSBezierPath()
    tick.lineWidth = radius * 0.26
    tick.lineCapStyle = .round
    tick.lineJoinStyle = .round
    tick.move(to: CGPoint(x: center.x - radius * 0.45, y: center.y + radius * 0.02))
    tick.line(to: CGPoint(x: center.x - radius * 0.1, y: center.y - radius * 0.35))
    tick.line(to: CGPoint(x: center.x + radius * 0.48, y: center.y + radius * 0.38))
    NSColor.white.setStroke()
    tick.stroke()
}

// Draw into a plain Core Graphics bitmap (no alpha: App Store icons must be opaque).
let context = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

accent.setFill()
NSBezierPath(rect: CGRect(x: 0, y: 0, width: size, height: size)).fill()

card(CGRect(x: 190, y: 540, width: 644, height: 230), fill: .white)
word("extol", color: ink, center: CGPoint(x: 460, y: 660))

card(CGRect(x: 190, y: 250, width: 644, height: 230), fill: successSoft, stroke: success)
word("laud", color: successInk, center: CGPoint(x: 440, y: 370))
checkBadge(center: CGPoint(x: 720, y: 365), radius: 62)

let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: output) as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Couldn't write \(output)") }
print("Wrote \(output)")
