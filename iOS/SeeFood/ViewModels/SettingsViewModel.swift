import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showResetConfirmation = false
    @Published var showLogoutConfirmation = false

    private let settingsService = SettingsService()
    private let cameraService = CameraService.shared
    private let imageCacheService = ImageCacheService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Initialize with default values or load from service
        settings = AppSettings(cameraId: "")

        // Subscribe to settings service
        settingsService.$settings
            .compactMap { $0 }
            .assign(to: &$settings)

        // Subscribe to camera service errors
        cameraService.$errorMessage
            .compactMap { $0 }
            .assign(to: &$errorMessage)

        // Load initial settings
        Task {
            await settingsService.loadSettings()
        }
    }

    func updateFridgeName(_ newName: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        await settingsService.updateFridgeName(newName)

        await MainActor.run {
            isLoading = false
        }
    }

    func testCameraConnection() async -> Bool {
        guard !settings.cameraId.isEmpty else { return false }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        let result = await cameraService.testCamera()

        await MainActor.run {
            isLoading = false
        }

        return result
    }

    func resetCamera() async {
        guard !settings.cameraId.isEmpty else { return }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
            showResetConfirmation = false
        }

        await settingsService.resetCamera()

        await MainActor.run {
            isLoading = false
            // Settings will be updated automatically through the subscription
        }
    }

    func logout() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            showLogoutConfirmation = false
        }

        await settingsService.logout()

        await MainActor.run {
            isLoading = false
        }
    }

    func clearImageCache() async {
        await MainActor.run {
            isLoading = true
        }

        await imageCacheService.clearAllCache()

        await MainActor.run {
            isLoading = false
        }
    }

    func refreshCameraStatus() async {
        guard !settings.cameraId.isEmpty else { return }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let status = try await cameraService.checkCameraStatus(cameraId: settings.cameraId)

            await MainActor.run {
                isLoading = false
                // Update status in the settings view
                // The status will be displayed through the computed properties
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    func clearError() {
        errorMessage = nil
        cameraService.clearError()
        settingsService.clearError()
    }

    // MARK: - User Actions

    func showResetDialog() {
        showResetConfirmation = true
    }

    func showLogoutDialog() {
        showLogoutConfirmation = true
    }

    // MARK: - Computed Properties

    var isSetupComplete: Bool {
        return !settings.cameraId.isEmpty
    }

    var cacheSize: String {
        return imageCacheService.formatCacheSize(imageCacheService.getCacheSize())
    }

    var appVersion: String {
        return Bundle.main.appVersion
    }

    var buildNumber: String {
        return Bundle.main.buildNumber
    }

    // MARK: - Validation

    func isValidFridgeName(_ name: String) -> Bool {
        let trimmed = name.trimmed()
        return !trimmed.isEmpty && trimmed.count <= 50
    }

    // MARK: - Camera Setup for QR Code

    func handleQRCodeResult(_ qrData: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let apiKey = try await cameraService.setupCamera(qrData: qrData)

            // Load updated settings after successful camera setup
            await settingsService.loadSettings()

            await MainActor.run {
                isLoading = false
            }

            return true

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }

            return false
        }
    }

    // MARK: - Support Information

    var supportEmail: String {
        return "support@seefood.app"
    }

    var supportURL: URL? {
        return URL(string: "https://support.seefood.app")
    }

    var privacyPolicyURL: URL? {
        return URL(string: "https://seefood.app/privacy")
    }

    var termsOfServiceURL: URL? {
        return URL(string: "https://seefood.app/terms")
    }

    // MARK: - Diagnostic Information

    func getDiagnosticInfo() async -> [String: String] {
        let (email, userId) = await settingsService.getUserInfo()
        let cacheSize = imageCacheService.getCacheSize()

        return [
            "App Version": appVersion,
            "Build Number": buildNumber,
            "Camera ID": settings.cameraId,
            "Fridge Name": settings.fridgeName,
            "User ID": userId ?? "Not available",
            "User Email": email ?? "Not available",
            "Cache Size": ByteCountFormatter.string(fromByteCount: cacheSize, countStyle: .file),
            "Setup Complete": isSetupComplete.description,
            "System Version": UIDevice.current.systemVersion,
            "Device Model": UIDevice.current.model
        ]
    }

    func exportDiagnosticData() -> String? {
        Task {
            let diagnosticInfo = await getDiagnosticInfo()
            let jsonString = try? JSONSerialization.data(withJSONObject: diagnosticInfo, options: .prettyPrinted)

            if let data = jsonString,
               let string = String(data: data, encoding: .utf8) {
                return string
            }
        }

        return nil
    }
}