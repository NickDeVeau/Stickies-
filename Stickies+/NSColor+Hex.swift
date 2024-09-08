import Cocoa

extension NSColor {
    convenience init?(hex: String) {
        var sanitizedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if sanitizedHex.hasPrefix("#") { sanitizedHex.remove(at: sanitizedHex.startIndex) }
        guard sanitizedHex.count == 8, let rgbValue = UInt32(sanitizedHex, radix: 16) else { return nil }
        self.init(red: CGFloat((rgbValue >> 24) & 0xFF) / 255.0,
                  green: CGFloat((rgbValue >> 16) & 0xFF) / 255.0,
                  blue: CGFloat((rgbValue >> 8) & 0xFF) / 255.0,
                  alpha: CGFloat(rgbValue & 0xFF) / 255.0)
    }
}
