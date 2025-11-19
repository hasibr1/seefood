import Foundation
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var images: [FridgeImage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoadingMore = false
    @Published var hasMoreImages = true

    private let cameraService = CameraService.shared
    private let settingsService = SettingsService()
    private let imageCacheService = ImageCacheService.shared
    private var cancellables = Set<AnyCancellable>()

    private var currentOffset = 0
    private let pageSize = 24

    init() {
        // Subscribe to settings changes
        settingsService.$settings
            .sink { [weak self] settings in
                if settings != nil {
                    self?.loadHistory()
                }
            }
            .store(in: &cancellables)
    }

    func loadHistory() async {
        guard let settings = await settingsService.settings else { return }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
            images = []
            currentOffset = 0
            hasMoreImages = true
        }

        do {
            let fetchedImages = try await cameraService.getImageHistory(
                cameraId: settings.cameraId,
                limit: pageSize,
                offset: currentOffset
            )

            await MainActor.run {
                images = fetchedImages
                currentOffset = fetchedImages.count
                hasMoreImages = fetchedImages.count == pageSize
                isLoading = false
            }

            // Preload thumbnails for better user experience
            await imageCacheService.preloadImages(fetchedImages)

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
                hasMoreImages = false
            }
        }
    }

    func loadMoreImages() async {
        guard let settings = await settingsService.settings,
              !isLoadingMore && hasMoreImages else { return }

        await MainActor.run {
            isLoadingMore = true
        }

        do {
            let fetchedImages = try await cameraService.getImageHistory(
                cameraId: settings.cameraId,
                limit: pageSize,
                offset: currentOffset
            )

            await MainActor.run {
                images.append(contentsOf: fetchedImages)
                currentOffset += fetchedImages.count
                hasMoreImages = fetchedImages.count == pageSize
                isLoadingMore = false
            }

            // Preload thumbnails for newly loaded images
            await imageCacheService.preloadImages(fetchedImages)

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoadingMore = false
            }
        }
    }

    func deleteImage(_ image: FridgeImage) async {
        // This would be implemented with a delete API endpoint
        // For now, we'll just remove it from the local array
        await MainActor.run {
            images.removeAll { $0.id == image.id }
        }

        // Also remove from cache
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagePath = cacheDirectory.appendingPathComponent("ImageCache/\(image.id.uuidString).jpg")
        let thumbnailPath = cacheDirectory.appendingPathComponent("ImageCache/\(image.id.uuidString)_thumb.jpg")

        try? fileManager.removeItem(at: imagePath)
        try? fileManager.removeItem(at: thumbnailPath)
    }

    func refreshHistory() async {
        await loadHistory()
    }

    func clearError() {
        errorMessage = nil
        cameraService.clearError()
    }

    // MARK: - Computed Properties

    var isEmpty: Bool {
        return images.isEmpty && !isLoading
    }

    var emptyStateMessage: String {
        if isLoading {
            return "Loading history..."
        } else {
            return "No images in the last 24 hours. Pull down to refresh or capture a new image."
        }
    }

    // MARK: - Image Loading

    func getCachedThumbnail(for image: FridgeImage) async -> UIImage? {
        return await imageCacheService.getCachedImage(id: image.id, isThumbnail: true)
    }

    func loadImage(for image: FridgeImage, isThumbnail: Bool = false) async -> UIImage? {
        do {
            let url = isThumbnail ? image.thumbnailURL : image.imageURL
            return try await imageCacheService.loadImage(from: url, id: image.id, isThumbnail: isThumbnail)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load image: \(error.localizedDescription)"
            }
            return nil
        }
    }

    // MARK: - Date Grouping

    func groupedImages() -> [(date: Date, images: [FridgeImage])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: images) { image in
            calendar.startOfDay(for: image.capturedAt)
        }

        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, images: $0.value) }
    }

    func dateHeader(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isToday(date) {
            return "Today"
        } else if calendar.isYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }

    // MARK: - Search and Filter

    func searchImages(text: String) -> [FridgeImage] {
        if text.isEmpty {
            return images
        }

        return images.filter { image in
            // For now, just search by date formatting
            // In the future, this could search by detected food items
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            let dateString = formatter.string(from: image.capturedAt)
            return dateString.localizedCaseInsensitiveContains(text)
        }
    }

    func filterImagesByDateRange(from startDate: Date, to endDate: Date) -> [FridgeImage] {
        return images.filter { image in
            return image.capturedAt >= startDate && image.capturedAt <= endDate
        }
    }

    // MARK: - Statistics

    var totalImages: Int {
        return images.count
    }

    var totalStorageUsed: String {
        let totalSize = images.reduce(0) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var averageFileSize: String {
        guard !images.isEmpty else { return "0 KB" }
        let totalSize = images.reduce(0) { $0 + $1.fileSize }
        let averageSize = totalSize / Int64(images.count)
        return ByteCountFormatter.string(fromByteCount: averageSize, countStyle: .file)
    }

    func imagesForToday() -> [FridgeImage] {
        let calendar = Calendar.current
        return images.filter { calendar.isToday($0.capturedAt) }
    }

    var imagesTodayCount: Int {
        return imagesForToday().count
    }
}