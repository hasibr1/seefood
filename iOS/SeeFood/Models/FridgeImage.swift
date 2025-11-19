import Foundation

struct FridgeImage: Identifiable, Codable {
    let id: UUID
    let cameraId: String
    let imageURL: URL
    let thumbnailURL: URL
    let capturedAt: Date
    let fileSize: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case cameraId = "camera_id"
        case imageURL = "image_url"
        case thumbnailURL = "thumbnail_url"
        case capturedAt = "captured_at"
        case fileSize = "file_size"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        cameraId = try container.decode(String.self, forKey: .cameraId)

        // Handle URL decoding from string
        if let imageURLString = try? container.decode(String.self, forKey: .imageURL),
           let imageURL = URL(string: imageURLString) {
            self.imageURL = imageURL
        } else {
            throw DecodingError.dataCorruptedError(forKey: .imageURL, in: container, debugDescription: "Invalid URL string")
        }

        if let thumbnailURLString = try? container.decode(String.self, forKey: .thumbnailURL),
           let thumbnailURL = URL(string: thumbnailURLString) {
            self.thumbnailURL = thumbnailURL
        } else {
            throw DecodingError.dataCorruptedError(forKey: .thumbnailURL, in: container, debugDescription: "Invalid URL string")
        }

        // Handle date decoding
        let dateFormatter = ISO8601DateFormatter()
        if let dateString = try? container.decode(String.self, forKey: .capturedAt),
           let date = dateFormatter.date(from: dateString) {
            self.capturedAt = date
        } else {
            self.capturedAt = try container.decode(Date.self, forKey: .capturedAt)
        }

        fileSize = try container.decode(Int64.self, forKey: .fileSize)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(cameraId, forKey: .cameraId)
        try container.encode(imageURL.absoluteString, forKey: .imageURL)
        try container.encode(thumbnailURL.absoluteString, forKey: .thumbnailURL)

        let dateFormatter = ISO8601DateFormatter()
        try container.encode(dateFormatter.string(from: capturedAt), forKey: .capturedAt)

        try container.encode(fileSize, forKey: .fileSize)
    }
}