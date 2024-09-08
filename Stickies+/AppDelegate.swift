import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManagers: [WindowManager] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createNewNoteWindow()
        setupMainMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Perform any cleanup if necessary
    }

    @objc func createNewNoteWindow() {
        let windowManager = WindowManager() // Initialize a new window manager
        windowManager.setupMainWindow() // Setup the main window
        windowManagers.append(windowManager) // Keep track of all window managers
    }

    private func setupMainMenu() {
        let mainMenu = NSApplication.shared.mainMenu ?? NSMenu(title: "MainMenu")
        
        // Create "File" menu
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
