import Foundation

/// The six bundled ambient soundscapes.
enum AmbientSound: String, Codable, CaseIterable, Identifiable {
    case rain        = "rain"
    case crickets    = "crickets"
    case river       = "river"
    case cafe        = "cafe"
    case cityTraffic = "city_traffic"
    case airplane    = "airplane"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rain:        return "Rain"
        case .crickets:    return "Crickets"
        case .river:       return "River"
        case .cafe:        return "Café"
        case .cityTraffic: return "City Traffic"
        case .airplane:    return "Airplane"
        }
    }

    /// The filename (without extension) in the Resources/Sounds bundle directory.
    var fileName: String { rawValue }
    var fileExtension: String { "m4a" }
}
