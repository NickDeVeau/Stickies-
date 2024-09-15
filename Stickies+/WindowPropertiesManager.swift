import Cocoa

struct WindowProperties: Codable, Equatable {
    let id: UUID
    var color: NSColor
    var text: NSAttributedString
    var position: CGPoint
    var size: CGSize
    
    enum CodingKeys: String, CodingKey {
        case id, color, text, position, size
    }
    
    init(id: UUID = UUID(), color: NSColor, text: NSAttributedString, position: CGPoint, size: CGSize) {
        self.id = id
        self.color = color
        self.text = text
        self.position = position
        self.size = size
    }
    
    // Encode properties
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        
        // Encode color
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .color)
        
        // Encode attributed text
        let textData = try NSKeyedArchiver.archivedData(withRootObject: text, requiringSecureCoding: false)
        try container.encode(textData, forKey: .text)
        
        // Encode position and size
        try container.encode(position, forKey: .position)
        try container.encode(size, forKey: .size)
    }

    // Decode properties
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        
        // Decode color
        let colorData = try container.decode(Data.self, forKey: .color)
        guard let decodedColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? NSColor else {
            throw DecodingError.dataCorruptedError(forKey: .color, in: container, debugDescription: "Color data could not be decoded.")
        }
        color = decodedColor
        
        // Decode attributed text
        let textData = try container.decode(Data.self, forKey: .text)
        guard let decodedText = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(textData) as? NSAttributedString else {
            throw DecodingError.dataCorruptedError(forKey: .text, in: container, debugDescription: "Text data could not be decoded.")
        }
        text = decodedText
        
        // Decode position and size
        position = try container.decode(CGPoint.self, forKey: .position)
        size = try container.decode(CGSize.self, forKey: .size)
    }
}

class WindowPropertiesManager {
    static let shared = WindowPropertiesManager()
    static let propertiesKey = "StickyNotesProperties"

    // Save the properties to UserDefaults
    func saveWindowProperties(_ properties: [WindowProperties]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(properties)
            UserDefaults.standard.set(data, forKey: WindowPropertiesManager.propertiesKey)
            UserDefaults.standard.synchronize() // Ensure immediate synchronization
        } catch {
            print("Failed to save window properties: \(error.localizedDescription)")
        }
    }

    // Load the properties from UserDefaults
    func loadWindowProperties() -> [WindowProperties] {
        guard let data = UserDefaults.standard.data(forKey: WindowPropertiesManager.propertiesKey) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            let properties = try decoder.decode([WindowProperties].self, from: data)
            return properties
        } catch {
            print("Failed to load window properties: \(error.localizedDescription)")
            return []
        }
    }
}
