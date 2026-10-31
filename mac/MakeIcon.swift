import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let background = NSBezierPath(roundedRect: NSRect(x: 18, y: 18, width: 988, height: 988), xRadius: 220, yRadius: 220)
NSGradient(starting: NSColor(calibratedRed: 0.10, green: 0.24, blue: 0.41, alpha: 1), ending: NSColor(calibratedRed: 0.03, green: 0.07, blue: 0.18, alpha: 1))!.draw(in: background, angle: -60)
let stem = NSBezierPath()
stem.move(to: NSPoint(x: 470, y: 720)); stem.curve(to: NSPoint(x: 565, y: 880), controlPoint1: NSPoint(x: 435, y: 820), controlPoint2: NSPoint(x: 480, y: 890))
stem.line(to: NSPoint(x: 607, y: 830)); stem.curve(to: NSPoint(x: 545, y: 716), controlPoint1: NSPoint(x: 530, y: 840), controlPoint2: NSPoint(x: 530, y: 775)); stem.close()
NSColor(calibratedRed: 0.45, green: 0.62, blue: 0.25, alpha: 1).setFill(); stem.fill()
for (x, width, top, bottom) in [(140.0, 410.0, 760.0, 192.0), (475.0, 410.0, 760.0, 192.0), (320.0, 390.0, 778.0, 170.0)] {
    let rib = NSBezierPath(ovalIn: NSRect(x: x, y: bottom, width: width, height: top - bottom))
    NSGradient(starting: NSColor(calibratedRed: 1, green: 0.76, blue: 0.30, alpha: 1), ending: NSColor(calibratedRed: 0.91, green: 0.26, blue: 0.08, alpha: 1))!.draw(in: rib, angle: -75)
}
let face = NSColor(calibratedRed: 0.23, green: 0.12, blue: 0.20, alpha: 1)
func triangle(_ a: NSPoint, _ b: NSPoint, _ c: NSPoint) {
    let p = NSBezierPath(); p.move(to: a); p.line(to: b); p.line(to: c); p.close(); face.setFill(); p.fill()
}
triangle(NSPoint(x: 265,y: 540), NSPoint(x: 385,y: 630), NSPoint(x: 420,y: 515))
triangle(NSPoint(x: 607,y: 515), NSPoint(x: 645,y: 630), NSPoint(x: 765,y: 540))
triangle(NSPoint(x: 478,y: 480), NSPoint(x: 517,y: 545), NSPoint(x: 550,y: 480))
let smile = NSBezierPath()
smile.move(to: NSPoint(x: 250,y: 435)); smile.curve(to: NSPoint(x: 780,y: 435), controlPoint1: NSPoint(x: 435,y: 328), controlPoint2: NSPoint(x: 620,y: 328))
smile.curve(to: NSPoint(x: 250,y: 435), controlPoint1: NSPoint(x: 710,y: 180), controlPoint2: NSPoint(x: 325,y: 185)); smile.close(); face.setFill(); smile.fill()
NSColor(calibratedRed: 1, green: 0.88, blue: 0.49, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 373, y: 338, width: 50, height: 55)).fill()
NSBezierPath(rect: NSRect(x: 603, y: 282, width: 50, height: 55)).fill()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
