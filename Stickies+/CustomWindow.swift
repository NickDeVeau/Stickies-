import Cocoa

class CustomWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}
