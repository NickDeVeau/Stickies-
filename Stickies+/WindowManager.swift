import Cocoa

protocol WindowFocusDelegate: AnyObject {
    func windowDidBecomeActive(_ windowManager: WindowManager)
}

class WindowManager: NSObject, NSWindowDelegate {
    weak var delegate: WindowFocusDelegate?
    var window: CustomWindow!
    var closeButton: NSButton!
    var titleBarView: DraggableTitleBar!
    var textView: CustomTextView!
    var backgroundView: NSView!
    var isHalfTransparent: Bool = false

    func setupMainWindow(with properties: WindowProperties? = nil) {
        setupWindow(with: properties)
        setupBackgroundView(with: properties)
        setupTitleBar()
        setupCloseButton()
        setupTextView(with: properties)
        ColorMenuManager.shared.updateColorMenuItems(target: self)
        updateCloseButtonColor()
        showCloseButtonIfNeeded()
    }

    private func setupWindow(with properties: WindowProperties?) {
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
        let windowSize = properties?.size ?? CGSize(width: 300, height: 300)
        let windowOrigin = properties?.position ?? CGPoint(x: (screenSize.width - windowSize.width) / 2, y: (screenSize.height - windowSize.height) / 2)
        let windowFrame = NSRect(origin: windowOrigin, size: windowSize)

        window = CustomWindow(contentRect: windowFrame, styleMask: [.borderless, .resizable], backing: .buffered, defer: false)
        window.delegate = self
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
    }

    private func setupBackgroundView(with properties: WindowProperties?) {
        backgroundView = NSView(frame: window.frame)
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 10
        backgroundView.layer?.masksToBounds = true
        backgroundView.layer?.backgroundColor = (properties?.color ?? NSColor.yellow).cgColor
        window.contentView = backgroundView
    }

    private func setupTitleBar() {
        titleBarView = DraggableTitleBar(frame: NSRect(x: 0, y: backgroundView.frame.height - 20, width: backgroundView.frame.width, height: 20))
        titleBarView.wantsLayer = true
        titleBarView.layer?.backgroundColor = NSColor.clear.cgColor
        titleBarView.layer?.cornerRadius = 10
        titleBarView.autoresizingMask = [.width, .minYMargin]
        backgroundView.addSubview(titleBarView)
    }

    private func setupCloseButton() {
        closeButton = NSButton(frame: NSRect(x: 5, y: 2, width: 16, height: 16))
        closeButton.bezelStyle = .regularSquare
        closeButton.isBordered = false
        closeButton.isHidden = true
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        closeButton.autoresizingMask = [.maxXMargin, .minYMargin]
        titleBarView.addSubview(closeButton)
    }

    private func setupTextView(with properties: WindowProperties?) {
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: backgroundView.frame.width, height: backgroundView.frame.height - 20))
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.autoresizingMask = [.width, .height]

        textView = CustomTextView(frame: scrollView.bounds)
        textView.autoresizingMask = [.width, .height]
        textView.backgroundColor = .clear
        textView.textColor = .black
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.isEditable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.string = properties?.text ?? "" // Restore text
        scrollView.documentView = textView
        backgroundView.addSubview(scrollView)
    }

    @objc func closeWindow() {
        guard window != nil else { return }
        window.delegate = nil  // Clear delegate to prevent potential calls on deallocated objects
        window.close()         // Close the window
    }

    func windowWillClose(_ notification: Notification) {
        // Ensure proper cleanup before the window is deallocated
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.windowManagers.removeAll(where: { $0 === self })
        }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        showCloseButtonIfNeeded()
        delegate?.windowDidBecomeActive(self)
    }

    func windowDidResignKey(_ notification: Notification) {
        hideCloseButtonIfNeeded()
    }

    func captureWindowProperties() -> WindowProperties? {
        guard window != nil else {
            print("Error: Attempting to access a deallocated window.")
            return nil
        }
        
        let color = NSColor(cgColor: backgroundView.layer?.backgroundColor ?? NSColor.yellow.cgColor) ?? .yellow
        let text = textView.string
        let position = window.frame.origin // Ensure window is not nil
        let size = window.frame.size
        return WindowProperties(color: color, text: text, position: position, size: size)
    }

    private func showCloseButtonIfNeeded() {
        if closeButton != nil {
            closeButton.isHidden = false
        }
    }

    private func hideCloseButtonIfNeeded() {
        if closeButton != nil {
            closeButton.isHidden = true
        }
    }

    func updateCloseButtonColor() {
        if let bgColor = backgroundView.layer?.backgroundColor, let bgNSColor = NSColor(cgColor: bgColor) {
            closeButton.attributedTitle = NSAttributedString(string: "✕", attributes: [.foregroundColor: contrastColor(for: bgNSColor)])
        }
    }

    private func contrastColor(for color: NSColor) -> NSColor {
        let lum = 0.299 * color.redComponent + 0.587 * color.greenComponent + 0.114 * color.blueComponent
        return lum > 0.5 ? .black : .white
    }
}
