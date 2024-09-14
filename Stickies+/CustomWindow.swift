import Cocoa

class CustomWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    weak var customDelegate: NSWindowDelegate? // Use a weak reference to avoid retain cycles

    override func close() {
        customDelegate?.windowWillClose?(Notification(name: Notification.Name("CustomWindowWillClose"), object: self))
        super.close()
    }
}
