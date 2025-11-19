import Foundation

struct AppSettings: Codable {
    let cameraId: String
    let fridgeName: String
    let refreshInterval: Int
    let notificationsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case cameraId = "camera_id"
        case fridgeName = "fridge_name"
        case refreshInterval = "refresh_interval"
        case notificationsEnabled = "notifications_enabled"
    }

    init(cameraId: String, fridgeName: String = "My Fridge", refreshInterval: Int = 0, notificationsEnabled: Bool = false) {
        self.cameraId = cameraId
        self.fridgeName = fridgeName
        self.refreshInterval = refreshInterval
        self.notificationsEnabled = notificationsEnabled
    }
}