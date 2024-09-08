import Cocoa

class CustomTextView: NSTextView {
    override func drawBackground(in rect: NSRect) {
        NSColor.clear.setFill()
        rect.fill()
    }
}
