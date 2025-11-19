import Foundation

struct CameraStatus: Codable {
    let cameraId: String
    let isOnline: Bool
    let lastCapture: Date?
    let batteryLevel: Float?
    let signalStrength: Int?

    enum CodingKeys: String, CodingKey {
        case cameraId = "camera_id"
        case isOnline = "is_online"
        case lastCapture = "last_capture"
        case batteryLevel = "battery_level"
        case signalStrength = "signal_strength"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cameraId = try container.decode(String.self, forKey: .cameraId)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        batteryLevel = try container.decodeIfPresent(Float.self, forKey: .batteryLevel)
        signalStrength = try container.decodeIfPresent(Int.self, forKey: .signalStrength)

        // Handle optional date decoding
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .lastCapture),
           !dateString.isEmpty {
            let dateFormatter = ISO8601DateFormatter()
            if let date = dateFormatter.date(from: dateString) {
                lastCapture = date
            } else {
                lastCapture = nil
            }
        } else {
            lastCapture = try container.decodeIfPresent(Date.self, forKey: .lastCapture)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cameraId, forKey: .cameraId)
        try container.encode(isOnline, forKey: .isOnline)
        try container.encodeIfPresent(batteryLevel, forKey: .batteryLevel)
        try container.encodeIfPresent(signalStrength, forKey: .signalStrength)

        if let lastCapture = lastCapture {
            let dateFormatter = ISO8601DateFormatter()
            try container.encode(dateFormatter.string(from: lastCapture), forKey: .lastCapture)
        }
    }
}