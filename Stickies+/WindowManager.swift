import Cocoa

protocol WindowFocusDelegate: AnyObject {
    func windowDidBecomeActive(_ windowManager: WindowManager)
}

class WindowManager: NSObject, NSWindowDelegate {
    weak var delegate: WindowFocusDelegate?
    let id: UUID
    var window: CustomWindow!
    var closeButton: NSButton!
    var titleBarView: DraggableTitleBar!
    var textView: CustomTextView!
    var backgroundView: NSView!
    var isHalfTransparent: Bool = false

    init(id: UUID = UUID()) {
        self.id = id
        super.init()
        print("WindowManager initialized with id: \(id)")
    }
    
    func setupMainWindow(with properties: WindowProperties? = nil) {
        setupWindow(with: properties)
        setupBackgroundView(with: properties)
        setupTitleBar()
        setupCloseButton()
        setupTextView(with: properties)
        ColorMenuManager.shared.updateColorMenuItems(target: self)
        updateCloseButtonColor()
        showCloseButtonIfNeeded()
        setupObservers()
    }

    private func setupWindow(with properties: WindowProperties?) {
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
        let windowSize = properties?.size ?? CGSize(width: 300, height: 300)
        let windowOrigin = properties?.position ?? CGPoint(x: (screenSize.width - windowSize.width) / 2, y: (screenSize.height - windowSize.height) / 2)
        let windowFrame = NSRect(origin: windowOrigin, size: windowSize)

        window = CustomWindow(contentRect: windowFrame, styleMask: [.borderless, .resizable], backing: .buffered, defer: false)
        window.delegate = self   // Set as NSWindowDelegate
        window.customDelegate = self // Set as custom delegate
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
        textView.isRichText = true // Enable rich text support
        textView.importsGraphics = true // Allows images and other graphics
        textView.allowsImageEditing = true // Allows image editing within the text view
        textView.allowsUndo = true
        textView.usesRuler = true // Enable ruler for text alignment and other rich text features

        // Set the attributed text content from properties
        if let attributedText = properties?.text {
            textView.textStorage?.setAttributedString(attributedText)
        } else {
            textView.string = ""
        }

        scrollView.documentView = textView
        backgroundView.addSubview(scrollView)
    }

    @objc func closeWindow() {
        guard window != nil else { return }
        window.delegate = nil  // Clear delegate to prevent potential calls on deallocated objects
        window.orderOut(nil)   // Immediately hides the window
        window.performClose(nil)  // Closes the window properly and calls the delegate
        
        saveProperties()
        
        // Only remove properties if the custom close button is used
        windowWillClose(Notification(name: Notification.Name("CustomWindowWillClose")))
    }
    
    func windowWillClose(_ notification: Notification) {
        print("windowWillClose called successfully")

        if notification.name.rawValue == "CustomWindowWillClose" {
            // Only remove the window properties when custom button is pressed
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                print("Attempting to remove properties for window with id: \(self.id)")
                appDelegate.windowProperties.removeAll(where: { $0.id == self.id })
                
                // Save the updated window properties
                WindowPropertiesManager.shared.saveWindowProperties(appDelegate.windowProperties)
                print("Properties removed for WindowManager with id: \(id). Remaining properties: \(appDelegate.windowProperties)")
                
                // Remove the window manager
                appDelegate.windowManagers.removeAll(where: { $0 === self })
            }
        }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        showCloseButtonIfNeeded()
        delegate?.windowDidBecomeActive(self)
    }

    func windowDidResignKey(_ notification: Notification) {
        hideCloseButtonIfNeeded()
    }

    func windowDidMove(_ notification: Notification) {
        saveProperties()
    }

    func windowDidResize(_ notification: Notification) {
        saveProperties()
    }

    func captureWindowProperties() -> WindowProperties? {
        guard window != nil else {
            print("Error: Attempting to access a deallocated window.")
            return nil
        }

        let color = NSColor(cgColor: backgroundView.layer?.backgroundColor ?? NSColor.yellow.cgColor) ?? .yellow
        let text = textView.attributedString()
        let position = window.frame.origin
        let size = window.frame.size
        return WindowProperties(id: id, color: color, text: text, position: position, size: size)
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

    // MARK: - Observers for Property Changes

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: NSText.didChangeNotification, object: textView)
    }

    @objc func textDidChange(_ notification: Notification) {
        saveProperties()
    }

    func saveProperties() {
        print("Clearing all stored data before saving new properties.")

        // Clear all stored data by removing the entry from UserDefaults
        UserDefaults.standard.removeObject(forKey: WindowPropertiesManager.propertiesKey)

        // Check if the window is still open before saving properties
        guard window != nil else {
            print("Window is nil, not saving properties.")
            return
        }

        // Save the new properties
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate,
              let properties = self.captureWindowProperties() else { return }

        // Update the window properties with the new properties
        appDelegate.updateWindowProperties(properties)
        
        // Print the current saved data
        if let data = UserDefaults.standard.data(forKey: WindowPropertiesManager.propertiesKey) {
            do {
                let decoder = JSONDecoder()
                let savedProperties = try decoder.decode([WindowProperties].self, from: data)
                print("Current saved properties: \(savedProperties)")
            } catch {
                print("Failed to decode current saved properties: \(error.localizedDescription)")
            }
        } else {
            print("No properties are currently saved.")
        }
    }

    deinit {
        print("WindowManager deallocated with id: \(id)")
        NotificationCenter.default.removeObserver(self)
    }
}
