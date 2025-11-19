import Foundation

struct Constants {
    struct API {
        static let baseURL = "https://api.seefood.app"
        static let version = "v1"

        struct Endpoints {
            static let register = "/auth/register"
            static let login = "/auth/login"
            static let connectCamera = "/cameras/connect"
            static let testCamera = "/cameras/test"
            static let userProfile = "/user/profile"

            static func cameraStatus(cameraId: String) -> String {
                return "/cameras/\(cameraId)/status"
            }

            static func captureImage(cameraId: String) -> String {
                return "/cameras/\(cameraId)/capture"
            }

            static func latestImage(cameraId: String) -> String {
                return "/cameras/\(cameraId)/latest"
            }

            static func imageHistory(cameraId: String) -> String {
                return "/cameras/\(cameraId)/history"
            }
        }

        struct Headers {
            static let apiKey = "X-API-Key"
            static let contentType = "Content-Type"
            static let accept = "Accept"
        }

        struct Timeout {
            static let short: TimeInterval = 10.0
            static let medium: TimeInterval = 30.0
            static let long: TimeInterval = 60.0
        }
    }

    struct App {
        static let name = "SeeFood"
        static let bundleIdentifier = "com.yourcompany.seefood"
        static let version = "1.0.0"

        struct Cache {
            static let imageExpirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
            static let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
        }

        struct Camera {
            static let captureTimeout: TimeInterval = 30.0
            static let maxRetryAttempts = 3
            static let retryDelay: TimeInterval = 2.0
        }

        struct UI {
            static let animationDuration: TimeInterval = 0.3
            static let refreshDelay: TimeInterval = 1.0
        }
    }

    struct Errors {
        static let networkErrorMessage = "Network error occurred. Please check your connection."
        static let authenticationErrorMessage = "Authentication failed. Please log in again."
        static let cameraOfflineMessage = "Camera is offline. Please check the device connection."
        static let captureTimeoutMessage = "Image capture timed out. Please try again."
        static let invalidQRCodeMessage = "Invalid QR code. Please scan a valid SeeFood camera QR code."
        static let expiredTokenMessage = "Setup token has expired. Please generate a new QR code."
    }
}