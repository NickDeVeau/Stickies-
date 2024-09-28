import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManagers: [WindowManager] = []
    var windowProperties: [WindowProperties] = []
    var activeWindowManager: WindowManager?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //clearAllUserDefaults()
        loadSavedWindows()
        setupMainMenu()
    }
    
    func clearAllUserDefaults() {
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
        UserDefaults.standard.synchronize() // Ensure all changes are saved immediately
        print("All UserDefaults have been cleared.")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Preserve window properties on application termination
        saveAllWindows()
    }

    // Determine how to handle quitting based on the quit method
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Preserve all windows and their contents unless they were closed by the custom 'X' button
        saveAllWindows()
        return .terminateNow
    }

    @objc func createNewNote() {
        createNewNoteWindow(with: nil)
    }

    func createNewNoteWindow(with properties: WindowProperties? = nil) {
        let id = properties?.id ?? UUID()
        let windowManager = WindowManager(id: id)
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
        fileMenu.addItem(NSMenuItem(title: "Save Note", action: #selector(saveNote), keyEquivalent: "s"))
        fileMenu.addItem(NSMenuItem(title: "Open Note", action: #selector(openNote), keyEquivalent: "o"))

        NSApplication.shared.mainMenu = mainMenu
    }


    @objc func saveNote() {
        guard let activeWindow = activeWindowManager else {
            print("No active window to save.")
            return
        }
        if let properties = activeWindow.captureWindowProperties() {
            exportWindowPropertiesToFile(properties)
        } else {
            print("Failed to capture properties for the active window.")
        }
    }
    
    @objc func openNote() {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["json"]
        openPanel.begin { [weak self] response in
            if response == .OK, let url = openPanel.url {
                self?.loadWindowFromFile(url)
            }
        }
    }

    func loadWindowFromFile(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let properties = try decoder.decode(WindowProperties.self, from: data)
            createNewNoteWindow(with: properties)
        } catch {
            print("Failed to load window properties: \(error)")
        }
    }

    func exportWindowPropertiesToFile(_ properties: WindowProperties) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["json"]
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try encoder.encode(properties)
                    try data.write(to: url)
                    print("File saved: \(url.absoluteString)")
                } catch {
                    print("Failed to save file: \(error)")
                }
            }
        }
    }

    private func loadSavedWindows() {
        let savedProperties = WindowPropertiesManager.shared.loadWindowProperties()
        windowProperties = savedProperties
        for properties in savedProperties {
            createNewNoteWindow(with: properties)
        }
    }

    private func saveAllWindows() {
        WindowPropertiesManager.shared.saveWindowProperties(windowProperties)
    }

    func updateWindowProperties(_ properties: WindowProperties) {
        windowProperties.removeAll(where: { $0.id == properties.id })
        windowProperties.append(properties)
        WindowPropertiesManager.shared.saveWindowProperties(windowProperties)
    }
}

// Extension to handle window focus changes
extension AppDelegate: WindowFocusDelegate {
    func windowDidBecomeActive(_ windowManager: WindowManager) {
        activeWindowManager = windowManager
        ColorMenuManager.shared.updateColorMenuItems(target: activeWindowManager)
    }
}
