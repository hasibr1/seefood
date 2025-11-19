import Foundation
import Combine

@MainActor
class FridgeViewModel: ObservableObject {
    @Published var currentImage: FridgeImage?
    @Published var cameraStatus: CameraStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    @Published var lastRefreshTime: Date?

    private let cameraService = CameraService.shared
    private let settingsService = SettingsService()
    private let imageCacheService = ImageCacheService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to camera service loading state
        cameraService.$isLoading
            .assign(to: &$isLoading)

        cameraService.$errorMessage
            .compactMap { $0 }
            .assign(to: &$errorMessage)

        // Subscribe to settings changes
        settingsService.$settings
            .sink { [weak self] settings in
                if settings != nil {
                    self?.loadInitialData()
                }
            }
            .store(in: &cancellables)
    }

    func loadInitialData() {
        Task {
            await checkStatus()
            await loadLatestImage()
        }
    }

    func refreshImage() async {
        guard let settings = await settingsService.settings else { return }

        await MainActor.run {
            isRefreshing = true
            errorMessage = nil
        }

        do {
            let newImage = try await cameraService.captureImage(cameraId: settings.cameraId)

            await MainActor.run {
                currentImage = newImage
                lastRefreshTime = Date()
                isRefreshing = false
            }

            // Cache the new image
            await imageCacheService.cacheImage(newImage)

            // Update status after capture
            await checkStatus()

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isRefreshing = false
            }
        }
    }

    func checkStatus() async {
        guard let settings = await settingsService.settings else { return }

        do {
            let status = try await cameraService.checkCameraStatus(cameraId: settings.cameraId)

            await MainActor.run {
                cameraStatus = status
            }
        } catch {
            await MainActor.run {
                // Don't show error for status checks, just update online status
                if var currentStatus = cameraStatus {
                    currentStatus = CameraStatus(
                        cameraId: currentStatus.cameraId,
                        isOnline: false,
                        lastCapture: currentStatus.lastCapture,
                        batteryLevel: nil,
                        signalStrength: nil
                    )
                    cameraStatus = currentStatus
                }
            }
        }
    }

    func loadLatestImage() async {
        guard let settings = await settingsService.settings else { return }

        do {
            let latestImage = try await cameraService.getLatestImage(cameraId: settings.cameraId)

            await MainActor.run {
                currentImage = latestImage
            }

            // Cache the image if it exists
            if let image = latestImage {
                await imageCacheService.cacheImage(image)
            }

        } catch {
            await MainActor.run {
                // Don't show error for loading latest image, it might just not exist
                print("Failed to load latest image: \(error)")
            }
        }
    }

    func testCamera() async -> Bool {
        guard let settings = await settingsService.settings else { return false }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let isOnline = try await cameraService.testCamera()

            await MainActor.run {
                isLoading = false
                if var currentStatus = cameraStatus {
                    currentStatus = CameraStatus(
                        cameraId: currentStatus.cameraId,
                        isOnline: isOnline,
                        lastCapture: currentStatus.lastCapture,
                        batteryLevel: currentStatus.batteryLevel,
                        signalStrength: currentStatus.signalStrength
                    )
                    cameraStatus = currentStatus
                }
            }

            return isOnline

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }

            return false
        }
    }

    func clearError() {
        errorMessage = nil
        cameraService.clearError()
    }

    // MARK: - Computed Properties

    var isCameraOnline: Bool {
        return cameraStatus?.isOnline ?? false
    }

    var lastCaptureText: String {
        guard let lastCapture = cameraStatus?.lastCapture else {
            return "No images yet"
        }
        return lastCapture.timeAgoDisplay()
    }

    var batteryLevelText: String? {
        guard let batteryLevel = cameraStatus?.batteryLevel else { return nil }
        return "\(Int(batteryLevel * 100))%"
    }

    var signalStrengthText: String? {
        guard let signalStrength = cameraStatus?.signalStrength else { return nil }
        return "\(signalStrength) bars"
    }

    var refreshText: String {
        if isRefreshing {
            return "Capturing..."
        } else if let lastRefreshTime = lastRefreshTime {
            return "Updated \(lastRefreshTime.timeAgoDisplay())"
        } else {
            return "Pull to refresh"
        }
    }

    // MARK: - Pull to Refresh Logic

    func handlePullToRefresh() async {
        await refreshImage()
    }

    // MARK: - Image Loading with Caching

    func getCachedImage() async -> UIImage? {
        guard let currentImage = currentImage else { return nil }
        return await imageCacheService.getCachedImage(id: currentImage.id)
    }

    func loadImage() async -> UIImage? {
        guard let currentImage = currentImage else { return nil }

        do {
            return try await imageCacheService.loadImage(from: currentImage.imageURL, id: currentImage.id)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load image: \(error.localizedDescription)"
            }
            return nil
        }
    }
}