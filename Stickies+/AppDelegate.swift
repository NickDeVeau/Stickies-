import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManagers: [WindowManager] = []
    var activeWindowManager: WindowManager? // Keeps track of the currently active window

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createNewNoteWindow()
        setupMainMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Perform any cleanup if necessary
    }

    @objc func createNewNoteWindow() {
        let windowManager = WindowManager()
        windowManager.delegate = self // Assign delegate to track active window
        windowManager.setupMainWindow()
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
        fileMenu.addItem(NSMenuItem(title: "New Note", action: #selector(createNewNoteWindow), keyEquivalent: "n"))

        NSApplication.shared.mainMenu = mainMenu
    }
}

// Extension to handle window focus changes
extension AppDelegate: WindowFocusDelegate {
    func windowDidBecomeActive(_ windowManager: WindowManager) {
        activeWindowManager = windowManager
        ColorMenuManager.shared.updateColorMenuItems(target: activeWindowManager)
    }
}
