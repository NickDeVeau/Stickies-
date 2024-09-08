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
            ("Soft Pink", "#FFC0CB" + transparencySuffix), ("Light Blue", "#ADD8E6" + transparencySuffix),
            ("Pale Green", "#98FB98" + transparencySuffix), ("Lavender", "#E6E6FA" + transparencySuffix),
            ("Beige", "#F5F5DC" + transparencySuffix), ("Mint Cream", "#F5FFFA" + transparencySuffix),
            ("Azure", "#F0FFFF" + transparencySuffix), ("Honeydew", "#F0FFF0" + transparencySuffix),
            ("Misty Rose", "#FFE4E1" + transparencySuffix), ("Light Coral", "#F08080" + transparencySuffix),
            ("Wheat", "#F5DEB3" + transparencySuffix), ("Khaki", "#F0E68C" + transparencySuffix),
            ("Silver", "#C0C0C0" + transparencySuffix), ("Sky Blue", "#87CEEB" + transparencySuffix),
            ("Mellow Apricot", "#F8B878" + transparencySuffix)
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
