import Cocoa

struct WindowProperties: Codable {
    var color: NSColor
    var text: String
    var position: CGPoint
    var size: CGSize
    
    enum CodingKeys: String, CodingKey {
        case color, text, position, size
    }
    
    // Custom initializer to avoid extra arguments error
    init(color: NSColor, text: String, position: CGPoint, size: CGSize) {
        self.color = color
        self.text = text
        self.position = position
        self.size = size
    }
    
    // Encode NSColor to Data for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .color)
        try container.encode(text, forKey: .text)
        try container.encode(position, forKey: .position)
        try container.encode(size, forKey: .size)
    }

    // Decode Data back to NSColor for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let colorData = try container.decode(Data.self, forKey: .color)
        guard let decodedColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? NSColor else {
            throw DecodingError.dataCorruptedError(forKey: .color, in: container, debugDescription: "Color data could not be decoded.")
        }
        color = decodedColor
        text = try container.decode(String.self, forKey: .text)
        position = try container.decode(CGPoint.self, forKey: .position)
        size = try container.decode(CGSize.self, forKey: .size)
    }
}

class WindowPropertiesManager {
    static let shared = WindowPropertiesManager()
    private let propertiesKey = "StickyNotesProperties"

    // Save the properties to UserDefaults
    func saveWindowProperties(_ properties: [WindowProperties]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(properties)
            UserDefaults.standard.set(data, forKey: propertiesKey)
            UserDefaults.standard.synchronize() // Ensure immediate synchronization
        } catch {
            print("Failed to save window properties: \(error.localizedDescription)")
        }
    }

    // Load the properties from UserDefaults
    func loadWindowProperties() -> [WindowProperties] {
        guard let data = UserDefaults.standard.data(forKey: propertiesKey) else {
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
