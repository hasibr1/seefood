import Foundation
import Combine

enum CameraError: LocalizedError {
    case invalidQRCode
    case expiredToken
    case cameraOffline
    case networkError(Error)
    case authenticationError
    case captureTimeout
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidQRCode:
            return Constants.Errors.invalidQRCodeMessage
        case .expiredToken:
            return Constants.Errors.expiredTokenMessage
        case .cameraOffline:
            return Constants.Errors.cameraOfflineMessage
        case .networkError(let error):
            return "\(Constants.Errors.networkErrorMessage) \(error.localizedDescription)"
        case .authenticationError:
            return Constants.Errors.authenticationErrorMessage
        case .captureTimeout:
            return Constants.Errors.captureTimeoutMessage
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

class CameraService: ObservableObject {
    static let shared = CameraService()

    private let baseURL = Constants.API.baseURL
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()

    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    // MARK: - Camera Setup

    func setupCamera(qrData: String) async throws -> String {
        guard let qrDataJSON = parseQRCodeData(qrData) else {
            throw CameraError.invalidQRCode
        }

        let setupToken = qrDataJSON["setup_token"] as? String ?? ""
        let cameraId = qrDataJSON["camera_id"] as? String ?? ""

        guard !setupToken.isEmpty else {
            throw CameraError.invalidQRCode
        }

        // Get user info for setup
        let settingsService = SettingsService()
        let (_, userId) = await settingsService.getUserInfo()

        guard let userId = userId else {
            throw CameraError.authenticationError
        }

        let url = URL(string: "\(baseURL)\(Constants.API.Endpoints.connectCamera)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "setupToken": setupToken,
            "userId": userId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CameraError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dataDict = jsonResponse["data"] as? [String: Any],
                      let apiKey = dataDict["apiKey"] as? String else {
                    throw CameraError.invalidResponse
                }

                // Save API key
                await settingsService.saveAPIKey(apiKey)

                return apiKey
            case 401:
                throw CameraError.expiredToken
            case 409:
                throw CameraError.invalidQRCode
            default:
                throw CameraError.networkError(URLError(.init(rawValue: httpResponse.statusCode)))
            }
        } catch {
            if error is CameraError {
                throw error
            }
            throw CameraError.networkError(error)
        }
    }

    // MARK: - Camera Operations

    func testCamera() async throws -> Bool {
        guard let apiKey = await getAPIKey() else {
            throw CameraError.authenticationError
        }

        let url = URL(string: "\(baseURL)\(Constants.API.Endpoints.testCamera)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: Constants.API.Headers.apiKey)

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CameraError.invalidResponse
            }

            return httpResponse.statusCode == 200
        } catch {
            throw CameraError.networkError(error)
        }
    }

    func checkCameraStatus(cameraId: String) async throws -> CameraStatus {
        guard let apiKey = await getAPIKey() else {
            throw CameraError.authenticationError
        }

        let endpoint = Constants.API.Endpoints.cameraStatus(cameraId: cameraId)
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: Constants.API.Headers.apiKey)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CameraError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(CameraStatus.self, from: data)
            case 401:
                throw CameraError.authenticationError
            case 404:
                throw CameraError.cameraOffline
            default:
                throw CameraError.networkError(URLError(.init(rawValue: httpResponse.statusCode)))
            }
        } catch {
            if error is DecodingError || error is CameraError {
                throw error
            }
            throw CameraError.networkError(error)
        }
    }

    func captureImage(cameraId: String) async throws -> FridgeImage {
        guard let apiKey = await getAPIKey() else {
            throw CameraError.authenticationError
        }

        let endpoint = Constants.API.Endpoints.captureImage(cameraId: cameraId)
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: Constants.API.Headers.apiKey)
        request.timeoutInterval = Constants.Camera.captureTimeout

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CameraError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                await MainActor.run {
                    isLoading = false
                }
                return try JSONDecoder().decode(FridgeImage.self, from: data)
            case 401:
                await MainActor.run {
                    isLoading = false
                }
                throw CameraError.authenticationError
            case 503:
                await MainActor.run {
                    isLoading = false
                }
                throw CameraError.cameraOffline
            default:
                await MainActor.run {
                    isLoading = false
                }
                throw CameraError.networkError(URLError(.init(rawValue: httpResponse.statusCode)))
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }

            if error is URLError && (error as! URLError).code == .timedOut {
                throw CameraError.captureTimeout
            }

            if error is DecodingError || error is CameraError {
                throw error
            }

            throw CameraError.networkError(error)
        }
    }

    func getLatestImage(cameraId: String) async throws -> FridgeImage? {
        guard let apiKey = await getAPIKey() else {
            throw CameraError.authenticationError
        }

        let endpoint = Constants.API.Endpoints.latestImage(cameraId: cameraId)
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: Constants.API.Headers.apiKey)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CameraError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(FridgeImage.self, from: data)
            case 404:
                return nil // No images found
            case 401:
                throw CameraError.authenticationError
            default:
                throw CameraError.networkError(URLError(.init(rawValue: httpResponse.statusCode)))
            }
        } catch {
            if error is DecodingError || error is CameraError {
                throw error
            }
            throw CameraError.networkError(error)
        }
    }

    func getImageHistory(cameraId: String, limit: Int = 24, offset: Int = 0) async throws -> [FridgeImage] {
        guard let apiKey = await getAPIKey() else {
            throw CameraError.authenticationError
        }

        let endpoint = Constants.API.Endpoints.imageHistory(cameraId: cameraId)
        var components = URLComponents(string: "\(baseURL)\(endpoint)")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components.url else {
            throw CameraError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: Constants.API.Headers.apiKey)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CameraError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dataDict = jsonResponse["data"] as? [String: Any],
                      let imagesArray = dataDict["images"] as? [[String: Any]] else {
                    throw CameraError.invalidResponse
                }

                let imageData = try JSONSerialization.data(withJSONObject: imagesArray)
                return try JSONDecoder().decode([FridgeImage].self, from: imageData)
            case 401:
                throw CameraError.authenticationError
            default:
                throw CameraError.networkError(URLError(.init(rawValue: httpResponse.statusCode)))
            }
        } catch {
            if error is DecodingError || error is CameraError {
                throw error
            }
            throw CameraError.networkError(error)
        }
    }

    // MARK: - Private Helpers

    private func getAPIKey() async -> String? {
        let settingsService = SettingsService()
        return await settingsService.getAPIKey()
    }

    private func parseQRCodeData(_ qrString: String) -> [String: Any]? {
        guard let data = qrString.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    func clearError() {
        errorMessage = nil
    }
}