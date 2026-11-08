// Convertit un SVG en PNG en préservant la transparence (Quick Look, lui,
// ajoute un fond blanc opaque : inutilisable pour le premier plan d'une icône).
//   swift scripts/svg2png.swift entrée.svg sortie.png largeur
// La hauteur suit les proportions du SVG (un logo horizontal reste horizontal).
import AppKit

let args = CommandLine.arguments
guard args.count == 4, let width = Int(args[3]), let image = NSImage(contentsOfFile: args[1]) else {
    FileHandle.standardError.write("usage : svg2png entrée.svg sortie.png largeur\n".data(using: .utf8)!)
    exit(1)
}
let ratio = image.size.width > 0 ? image.size.height / image.size.width : 1
let height = max(1, Int((Double(width) * ratio).rounded()))
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { exit(1) }
rep.size = NSSize(width: width, height: height)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor.clear.set()
NSRect(x: 0, y: 0, width: width, height: height).fill()
image.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
