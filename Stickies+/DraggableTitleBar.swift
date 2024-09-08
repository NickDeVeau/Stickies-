import Cocoa

class DraggableTitleBar: NSView {

    var initialLocation: NSPoint = NSZeroPoint

    override func mouseDown(with event: NSEvent) {
        // Capture the initial click location
        guard let window = self.window else { return }
        initialLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        // Calculate new window position
        guard let window = self.window else { return }
        let screenVisibleFrame = NSScreen.main?.visibleFrame ?? NSRect.zero
        var newOrigin = window.frame.origin

        // Current mouse location
        let currentLocation = event.locationInWindow

        // Calculate new origin
        newOrigin.x += (currentLocation.x - initialLocation.x)
        newOrigin.y += (currentLocation.y - initialLocation.y)

        // Ensure the window stays within the screen's visible frame
        let windowFrame = window.frame
        if (newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height) {
            newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height)
        }

        // Update the window position
        window.setFrameOrigin(newOrigin)
    }
}
