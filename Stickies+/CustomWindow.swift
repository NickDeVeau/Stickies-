import Cocoa

class CustomWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    weak var customDelegate: NSWindowDelegate? // Use a weak reference to avoid retain cycles

    override func close() {
        // Call the custom delegate's windowWillClose method if it exists
        super.close()
    }
}
