import Cocoa

// Custom Text View Subclass
class CustomTextView: NSTextView {
    override func drawBackground(in rect: NSRect) {
        // Prevent any background from being drawn
        NSColor.clear.setFill()
        rect.fill()
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: CustomWindow! // Use the custom window class
    var closeButton: NSButton!
    var titleBarView: DraggableTitleBar! // Make titleBarView a property
    var textView: CustomTextView! // Use the custom text view subclass
    var backgroundView: NSView! // A container view for background color
    var isHalfTransparent: Bool = false // Toggle state for transparency

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Define window size and position
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
        let windowSize = CGSize(width: 300, height: 300)
        let windowFrame = NSRect(x: (screenSize.width - windowSize.width) / 2,
                                 y: (screenSize.height - windowSize.height) / 2,
                                 width: windowSize.width,
                                 height: windowSize.height)

        // Create a borderless, resizable custom window
        window = CustomWindow(contentRect: windowFrame, styleMask: [.borderless, .resizable],
                              backing: .buffered, defer: false)
        window.delegate = self

        // Customize the window appearance
        window.isMovableByWindowBackground = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = false // Disable shadow for the window
        window.level = .floating

        // Set up the background view with rounded corners
        backgroundView = NSView(frame: windowFrame)
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 10
        backgroundView.layer?.masksToBounds = true
        backgroundView.layer?.backgroundColor = NSColor.yellow.cgColor
        window.contentView = backgroundView

        // Make the window key and visible
        window.makeKeyAndOrderFront(nil)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        // Create a custom title bar
        let titleBarHeight: CGFloat = 20.0
        titleBarView = DraggableTitleBar(frame: NSRect(x: 0, y: windowSize.height - titleBarHeight,
                                                       width: windowSize.width, height: titleBarHeight))
        titleBarView.wantsLayer = true
        titleBarView.layer?.backgroundColor = NSColor.clear.cgColor
        titleBarView.layer?.cornerRadius = 10
        titleBarView.autoresizingMask = [.width, .minYMargin]
        backgroundView.addSubview(titleBarView)

        // Add a close button to the title bar
        closeButton = NSButton(frame: NSRect(x: 5, y: 2, width: 16, height: 16))
        closeButton.bezelStyle = .regularSquare
        closeButton.isBordered = false
        closeButton.isHidden = true
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        closeButton.autoresizingMask = [.maxXMargin, .minYMargin]
        titleBarView.addSubview(closeButton)

        // Create a scrollable text view
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: windowSize.width,
                                                    height: windowSize.height - titleBarHeight))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]
        scrollView.drawsBackground = false

        // Create a transparent text view for content
        textView = CustomTextView(frame: scrollView.bounds)
        textView.autoresizingMask = [.width, .height]
        textView.backgroundColor = NSColor.clear
        textView.textColor = NSColor.black
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.isEditable = true
        textView.isRichText = false
        textView.allowsUndo = true
        scrollView.documentView = textView
        backgroundView.addSubview(scrollView)

        // Add menu actions for colors
        addColorMenuItems()

        // Initialize the closeButton color based on the initial background color
        updateCloseButtonColor()
    }

    @objc func closeWindow() {
        window.close()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        closeButton.isHidden = false
    }

    func windowDidResignKey(_ notification: Notification) {
        closeButton.isHidden = true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Code to tear down your application
    }

    func addColorMenuItems() {
        let mainMenu = NSApplication.shared.mainMenu ?? NSMenu(title: "MainMenu")
        let colorMenuItem = mainMenu.items.first { $0.title == "Color" } ?? NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        if colorMenuItem.submenu == nil {
            let colorMenu = NSMenu(title: "Color")
            colorMenuItem.submenu = colorMenu
            mainMenu.addItem(colorMenuItem)
        }
        let colorMenu = colorMenuItem.submenu!

        let transparencySuffix = isHalfTransparent ? "80" : "FF"
        let colors: [(String, String)] = [
            ("Soft Pink", "#FFC0CB" + transparencySuffix),
            ("Light Blue", "#ADD8E6" + transparencySuffix),
            ("Pale Green", "#98FB98" + transparencySuffix),
            ("Lavender", "#E6E6FA" + transparencySuffix),
            ("Beige", "#F5F5DC" + transparencySuffix),
            ("Mint Cream", "#F5FFFA" + transparencySuffix),
            ("Azure", "#F0FFFF" + transparencySuffix),
            ("Honeydew", "#F0FFF0" + transparencySuffix),
            ("Misty Rose", "#FFE4E1" + transparencySuffix),
            ("Light Coral", "#F08080" + transparencySuffix),
            ("Wheat", "#F5DEB3" + transparencySuffix),
            ("Khaki", "#F0E68C" + transparencySuffix),
            ("Silver", "#C0C0C0" + transparencySuffix),
            ("Sky Blue", "#87CEEB" + transparencySuffix),
            ("Mellow Apricot", "#F8B878" + transparencySuffix)
        ]

        colorMenu.removeAllItems()

        for (title, hex) in colors {
            let item = NSMenuItem(title: title, action: #selector(changeBackgroundColor(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = hex
            if let color = NSColor(hex: hex) {
                let attributedString = NSAttributedString(string: "● ", attributes: [.foregroundColor: color])
                let titleString = NSAttributedString(string: title)
                let combinedString = NSMutableAttributedString()
                combinedString.append(attributedString)
                combinedString.append(titleString)
                item.attributedTitle = combinedString
            }
            colorMenu.addItem(item)
        }

        let toggleItem = NSMenuItem(title: "Toggle Transparency", action: #selector(toggleTransparency), keyEquivalent: "t")
        toggleItem.target = self
        colorMenu.addItem(toggleItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc func changeBackgroundColor(_ sender: NSMenuItem) {
        if let hex = sender.representedObject as? String, let color = NSColor(hex: hex) {
            backgroundView.layer?.backgroundColor = color.cgColor
            updateCloseButtonColor()
        }
    }

    @objc func toggleTransparency() {
        isHalfTransparent.toggle() // Toggle the state
        addColorMenuItems() // Refresh the menu items with new transparency settings
    }

    func updateCloseButtonColor() {
        if let backgroundColor = backgroundView.layer?.backgroundColor, let bgNSColor = NSColor(cgColor: backgroundColor) {
            let contrastingColor = contrastColor(for: bgNSColor)
            let closeButtonTitle = NSAttributedString(string: "✕", attributes: [.foregroundColor: contrastingColor])
            closeButton.attributedTitle = closeButtonTitle
        }
    }

    func contrastColor(for color: NSColor) -> NSColor {
        let red = color.redComponent
        let green = color.greenComponent
        let blue = color.blueComponent
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.5 ? .black : .white
    }
}

// NSColor extension to support hex values with alpha
extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }
        guard hexSanitized.count == 8 else { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgbValue)
        let red = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
        let green = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
        let blue = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
        let alpha = CGFloat(rgbValue & 0x000000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
