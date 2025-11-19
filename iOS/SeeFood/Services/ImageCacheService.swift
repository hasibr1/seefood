import Foundation
import UIKit
import Combine

class ImageCacheService: ObservableObject {
    static let shared = ImageCacheService()

    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private var imageCache: [String: UIImage] = [:]
    private var memoryCache = NSCache<NSString, UIImage>()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Create cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure memory cache
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        // Set up memory warning notification
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.clearMemoryCache()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func cacheImage(_ fridgeImage: FridgeImage) async {
        await withTaskGroup(of: Void.self) { group in
            // Cache full image
            group.addTask {
                await self.cacheImageFromURL(fridgeImage.imageURL, id: fridgeImage.id.uuidString)
            }

            // Cache thumbnail
            group.addTask {
                await self.cacheImageFromURL(fridgeImage.thumbnailURL, id: "\(fridgeImage.id.uuidString)_thumb")
            }
        }
    }

    func getCachedImage(id: UUID, isThumbnail: Bool = false) async -> UIImage? {
        let cacheKey = isThumbnail ? "\(id.uuidString)_thumb" : id.uuidString

        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }

        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(cacheKey).jpg")
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        // Store in memory cache
        memoryCache.setObject(image, forKey: cacheKey as NSString, cost: data.count)

        return image
    }

    func loadImage(from url: URL, id: UUID, isThumbnail: Bool = false) async throws -> UIImage {
        let cacheKey = isThumbnail ? "\(id.uuidString)_thumb" : id.uuidString

        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }

        // Check disk cache
        if let cachedImage = await getCachedImage(id: id, isThumbnail: isThumbnail) {
            return cachedImage
        }

        // Download image
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ImageCacheService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }

        // Cache the image
        await cacheImageData(data, id: id, isThumbnail: isThumbnail)

        // Store in memory cache
        memoryCache.setObject(image, forKey: cacheKey as NSString, cost: data.count)

        return image
    }

    func preloadImages(_ fridgeImages: [FridgeImage]) async {
        await withTaskGroup(of: Void.self) { group in
            for fridgeImage in fridgeImages {
                group.addTask {
                    try? await self.loadImage(from: fridgeImage.thumbnailURL, id: fridgeImage.id, isThumbnail: true)
                }
            }
        }
    }

    func clearOldCache() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            let cutoffDate = Date().addingTimeInterval(-Constants.App.Cache.imageExpirationInterval)

            for fileURL in files {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.creationDateKey]),
                   let creationDate = resourceValues.creationDate,
                   creationDate < cutoffDate {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            print("Failed to clear old cache: \(error)")
        }
    }

    func clearAllCache() async {
        clearMemoryCache()

        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in files {
                try? fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to clear all cache: \(error)")
        }
    }

    func getCacheSize() -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var totalSize: Int64 = 0

            for fileURL in files {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }

            return totalSize
        } catch {
            return 0
        }
    }

    // MARK: - Private Methods

    private func cacheImageFromURL(_ url: URL, id: String) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            await cacheImageData(data, id: id, isThumbnail: id.contains("_thumb"))
        } catch {
            print("Failed to cache image from \(url): \(error)")
        }
    }

    private func cacheImageData(_ data: Data, id: UUID, isThumbnail: Bool) async {
        let cacheKey = isThumbnail ? "\(id.uuidString)_thumb" : id.uuidString
        await cacheImageData(data, id: cacheKey)
    }

    private func cacheImageData(_ data: Data, id: String, isThumbnail: Bool = false) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).jpg")

        do {
            try data.write(to: fileURL)

            // Also cache in memory if it's a thumbnail or small enough
            if isThumbnail || data.count < 1024 * 1024 { // 1MB threshold
                if let image = UIImage(data: data) {
                    memoryCache.setObject(image, forKey: id as NSString, cost: data.count)
                }
            }
        } catch {
            print("Failed to cache image data: \(error)")
        }
    }

    private func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    // MARK: - Convenience Methods

    func formatCacheSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}