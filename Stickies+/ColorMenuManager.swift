import Cocoa

class ColorMenuManager {
    static let shared = ColorMenuManager()

    func updateColorMenuItems(target: WindowManager?) {
        guard let target = target else { return } // Ensure we have a valid target
        
        let mainMenu = NSApplication.shared.mainMenu ?? NSMenu(title: "MainMenu")
        let colorMenuItem = mainMenu.items.first(where: { $0.title == "Color" }) ?? NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        
        if colorMenuItem.submenu == nil {
            colorMenuItem.submenu = NSMenu(title: "Color")
            mainMenu.addItem(colorMenuItem)
        }

        let transparencySuffix = target.isHalfTransparent ? "80" : "FF"
        let colors: [(String, String)] = [
            ("Soft Yellow", "#FFFBCC" + transparencySuffix),    // Default yellowish sticky note
            ("Blush Pink", "#FFB6C1" + transparencySuffix),      // Soft pink
            ("Sky Blue", "#87CEFA" + transparencySuffix),        // Light blue
            ("Mint Green", "#98FF98" + transparencySuffix),      // Soft mint green
            ("Lavender", "#D8BFD8" + transparencySuffix),        // Lavender
            ("Peach Puff", "#FFDAB9" + transparencySuffix),      // Peach
            ("Powder Blue", "#B0E0E6" + transparencySuffix),     // Powder blue
            ("Light Mint", "#E0FFF5" + transparencySuffix),      // Light mint cream
            ("Light Honeydew", "#F1FFE7" + transparencySuffix),  // Soft honeydew
            ("Misty Rose", "#FFE4E1" + transparencySuffix),      // Misty rose
            ("Coral Pink", "#FF6F61" + transparencySuffix),      // Light coral
            ("Soft Beige", "#FAF0E6" + transparencySuffix),      // Beige
            ("Pale Sky", "#CAE9FF" + transparencySuffix),        // Light sky blue
            ("Lemon Chiffon", "#FFFACD" + transparencySuffix),   // Soft lemon
            ("Periwinkle", "#CCCCFF" + transparencySuffix)       // Soft periwinkle
        ]

        let colorMenu = colorMenuItem.submenu!
        colorMenu.removeAllItems()
        colors.forEach { title, hex in
            let item = NSMenuItem(title: title, action: #selector(changeBackgroundColor(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = hex
            if let color = NSColor(hex: hex) {
                item.attributedTitle = NSAttributedString(string: "● \(title)", attributes: [.foregroundColor: color])
            }
            colorMenu.addItem(item)
        }

        let toggleItem = NSMenuItem(title: "Toggle Transparency", action: #selector(toggleTransparency), keyEquivalent: "t")
        toggleItem.target = self
        colorMenu.addItem(toggleItem)
        NSApplication.shared.mainMenu = mainMenu
    }

    @objc func changeBackgroundColor(_ sender: NSMenuItem) {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate,
              let activeWindowManager = appDelegate.activeWindowManager,
              let hex = sender.representedObject as? String,
              let color = NSColor(hex: hex) else { return }

        activeWindowManager.backgroundView.layer?.backgroundColor = color.cgColor
        activeWindowManager.updateCloseButtonColor()
    }

    @objc func toggleTransparency() {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate,
              let activeWindowManager = appDelegate.activeWindowManager else { return }

        activeWindowManager.isHalfTransparent.toggle()
        updateColorMenuItems(target: activeWindowManager)
    }
}
