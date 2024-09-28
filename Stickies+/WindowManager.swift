import Cocoa

protocol WindowFocusDelegate: AnyObject {
    func windowDidBecomeActive(_ windowManager: WindowManager)
}

class WindowManager: NSObject, NSWindowDelegate {
    weak var delegate: WindowFocusDelegate?
    let id: UUID
    var updateTimer: Timer?
    var window: CustomWindow!
    var closeButton: NSButton!
    var titleBarView: DraggableTitleBar!
    var advancedEditor: CustomTextView!        // Advanced Editor whose properties will be saved
    var standardEditor: CustomTextView!        // Standard Editor, non-saved, read-only
    var backgroundView: NSView!
    var isHalfTransparent: Bool = false
    var isAdvancedEditorVisible: Bool = true   // Track which editor is currently visible
    var scrollView: NSScrollView!
    private var auxiliaryPanelActive: Bool = false // Track if any auxiliary panel (like font or color) is active

    private let keywordHandler = KeywordHandler() // Instance of the new KeywordHandler

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
        setupTextEditors(with: properties) // Set up both editors
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
        window.delegate = self
        window.customDelegate = self
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .normal
        window.makeKeyAndOrderFront(nil)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
    }

    private func setupBackgroundView(with properties: WindowProperties?) {
        backgroundView = NSView(frame: window.frame)
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 10
        backgroundView.layer?.masksToBounds = true
        // Set default color to #FFFBCC (Soft Yellow)
        let defaultColor = NSColor(red: 1.0, green: 0.984, blue: 0.8, alpha: 1.0)  // #FFFBCC
        backgroundView.layer?.backgroundColor = (properties?.color ?? defaultColor).cgColor
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

    private func setupTextEditors(with properties: WindowProperties?) {
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: backgroundView.frame.width, height: backgroundView.frame.height - 20))
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.autoresizingMask = [.width, .height]

        // Set up the Advanced Editor
        advancedEditor = createTextView(isEditable: true, properties: properties?.text)
        
        // Set up the Standard Editor (read-only)
        standardEditor = createTextView(isEditable: false, properties: nil)

        // Initially set visibility states based on `isAdvancedEditorVisible`
        advancedEditor.isHidden = !isAdvancedEditorVisible
        standardEditor.isHidden = isAdvancedEditorVisible

        scrollView.documentView = isAdvancedEditorVisible ? advancedEditor : standardEditor
        backgroundView.addSubview(scrollView)
    }


    private func createTextView(isEditable: Bool, properties: NSAttributedString?) -> CustomTextView {
        let editor = CustomTextView(frame: scrollView.bounds)
        editor.autoresizingMask = [.width, .height]
        editor.backgroundColor = .clear
        editor.textColor = .black
        editor.font = NSFont.systemFont(ofSize: 14)
        editor.isEditable = isEditable
        editor.isRichText = true
        editor.importsGraphics = isEditable
        editor.allowsImageEditing = isEditable
        editor.allowsUndo = isEditable
        editor.usesRuler = isEditable

        if let attributedText = properties {
            editor.textStorage?.setAttributedString(attributedText)
        } else {
            editor.string = ""
        }

        return editor
    }

    @objc func toggleEditorVisibility() {
        if !auxiliaryPanelActive {
            isAdvancedEditorVisible.toggle()

            if !isAdvancedEditorVisible {
                // Copy and process the text from the advanced editor
                updateStandardEditorContent()
                // Start the timer
                startUpdateTimer()
            } else {
                // Invalidate the timer
                stopUpdateTimer()
            }

            // Set visibility of the editors
            advancedEditor.isHidden = !isAdvancedEditorVisible
            standardEditor.isHidden = isAdvancedEditorVisible
            scrollView.documentView = isAdvancedEditorVisible ? advancedEditor : standardEditor

            print("Toggled visibility. Advanced Editor visible: \(isAdvancedEditorVisible)")
        }
    }

    func startUpdateTimer() {
        // Invalidate any existing timer
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(updateStandardEditorContent), userInfo: nil, repeats: true)
    }

    func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @objc func updateStandardEditorContent() {
        print("updating")
        // Copy the advanced editor's text
        if let advancedAttributedText = advancedEditor.textStorage?.copy() as? NSAttributedString {
            let processedText = NSMutableAttributedString(attributedString: advancedAttributedText)
            
            // Evaluate expressions in the copied attributed text
            evaluateExpressionsInAttributedText(processedText)
            
            // Set the processed attributed text to the standard editor
            standardEditor.textStorage?.setAttributedString(processedText)
        }
    }


    private func evaluateExpressionsInAttributedText(_ attributedText: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: attributedText.length)
        
        // Store processed ranges and replacements
        var replacements: [(NSRange, NSAttributedString)] = []
        
        // Step 1: Collect replacements
        attributedText.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            let originalText = attributedText.attributedSubstring(from: range).string
            let processedText = keywordHandler.process(originalText)
            
            // Only replace if there is a change
            if originalText != processedText {
                // Create a new attributed string with the processed text but same attributes
                let processedAttributedString = NSAttributedString(string: processedText, attributes: attributes)
                replacements.append((range, processedAttributedString))
            }
        }
        
        // Step 2: Apply replacements in reverse order
        for (range, replacement) in replacements.reversed() {
            // Debugging: Print the range and replacement details before applying
            print("Replacing range: \(range) with text: \(replacement.string)")
            
            // Make sure the range is valid before applying the replacement
            guard range.location + range.length <= attributedText.length else {
                print("Invalid range, skipping replacement.")
                continue
            }
            
            attributedText.replaceCharacters(in: range, with: replacement)
        }
    }

    @objc func closeWindow() {
        guard window != nil else { return }
        window.delegate = nil
        window.orderOut(nil)
        window.performClose(nil)
        saveProperties()
        windowWillClose(Notification(name: Notification.Name("CustomWindowWillClose")))
    }

    func windowWillClose(_ notification: Notification) {
        print("windowWillClose called successfully")
        if notification.name.rawValue == "CustomWindowWillClose" {
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                print("Attempting to remove properties for window with id: \(self.id)")
                appDelegate.windowProperties.removeAll(where: { $0.id == self.id })
                WindowPropertiesManager.shared.saveWindowProperties(appDelegate.windowProperties)
                print("Properties removed for WindowManager with id: \(id). Remaining properties: \(appDelegate.windowProperties)")
                appDelegate.windowManagers.removeAll(where: { $0 === self })
            }
        }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        showCloseButtonIfNeeded()
        delegate?.windowDidBecomeActive(self)

        // Ensure the Advanced Editor remains active when the window becomes key
        if !isAdvancedEditorVisible {
            toggleEditorVisibility()
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        hideCloseButtonIfNeeded()

        // Only toggle to the Standard Editor when auxiliary panel is not active
        if !auxiliaryPanelActive && isAdvancedEditorVisible {
            toggleEditorVisibility()
        }
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
        let text = advancedEditor.attributedString()
        let position = window.frame.origin
        let size = window.frame.size
        return WindowProperties(id: id, color: color, text: text, position: position, size: size)
    }

    private func showCloseButtonIfNeeded() {
        closeButton?.isHidden = false
    }

    private func hideCloseButtonIfNeeded() {
        closeButton?.isHidden = true
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

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: NSText.didChangeNotification, object: advancedEditor)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.characters == "" {
                self?.toggleEditorVisibility()
                return nil
            }
            return event
        }
        
        // Observers to track auxiliary panel activity
        NotificationCenter.default.addObserver(self, selector: #selector(auxiliaryPanelDidOpen(_:)), name: NSWindow.didBecomeKeyNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(auxiliaryPanelDidClose(_:)), name: NSWindow.didResignKeyNotification, object: nil)
    }

    @objc private func auxiliaryPanelDidOpen(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Check if the window is a font or color panel
        if window.className == "NSFontPanel" || window.className == "NSColorPanel" {
            auxiliaryPanelActive = true
        }
    }

    @objc private func auxiliaryPanelDidClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Check if the window is a font or color panel
        if window.className == "NSFontPanel" || window.className == "NSColorPanel" {
            auxiliaryPanelActive = false
        }
    }

    @objc func textDidChange(_ notification: Notification) {
        saveProperties()
    }

    func saveProperties() {
        print("Clearing all stored data before saving new properties.")

        UserDefaults.standard.removeObject(forKey: WindowPropertiesManager.propertiesKey)

        guard window != nil else {
            print("Window is nil, not saving properties.")
            return
        }

        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate,
              let properties = self.captureWindowProperties() else { return }

        appDelegate.updateWindowProperties(properties)
        
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
        updateTimer?.invalidate()
    }

}
