import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManagers: [WindowManager] = []
    var activeWindowManager: WindowManager? // Keeps track of the currently active window

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        loadSavedWindows()
        setupMainMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        saveAllWindows() // Ensure this method is called to save the state
    }

    @objc func createNewNote() {
        createNewNoteWindow(with: nil)
    }

    func createNewNoteWindow(with properties: WindowProperties? = nil) {
        let windowManager = WindowManager()
        windowManager.delegate = self
        windowManager.setupMainWindow(with: properties)
        windowManagers.append(windowManager)
    }

    private func setupMainMenu() {
        let mainMenu = NSApplication.shared.mainMenu ?? NSMenu(title: "MainMenu")
        
        let fileMenuItem = mainMenu.items.first(where: { $0.title == "File" }) ?? NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        if fileMenuItem.submenu == nil {
            fileMenuItem.submenu = NSMenu(title: "File")
            mainMenu.addItem(fileMenuItem)
        }

        let fileMenu = fileMenuItem.submenu!
        fileMenu.addItem(NSMenuItem(title: "New Note", action: #selector(createNewNote), keyEquivalent: "n"))

        NSApplication.shared.mainMenu = mainMenu
    }

    private func loadSavedWindows() {
        let savedProperties = WindowPropertiesManager.shared.loadWindowProperties()
        for properties in savedProperties {
            createNewNoteWindow(with: properties)
        }
    }

    private func saveAllWindows() {
        // Use compactMap to filter out nil values and create a non-optional array
        let properties = windowManagers.compactMap { $0.captureWindowProperties() }
        WindowPropertiesManager.shared.saveWindowProperties(properties)
    }
}

// Extension to handle window focus changes
extension AppDelegate: WindowFocusDelegate {
    func windowDidBecomeActive(_ windowManager: WindowManager) {
        activeWindowManager = windowManager
        ColorMenuManager.shared.updateColorMenuItems(target: activeWindowManager)
    }
}
