import Foundation
import KeychainAccess
import Combine

@MainActor
class SettingsService: ObservableObject {
    @Published var settings: AppSettings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSetupComplete = false

    private let keychain = Keychain(service: Constants.App.bundleIdentifier)
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    private struct Keys {
        static let cameraId = "camera_id"
        static let fridgeName = "fridge_name"
        static let apiKey = "api_key"
        static let setupComplete = "setup_complete"
        static let userEmail = "user_email"
        static let userId = "user_id"
    }

    init() {
        // Subscribe to settings changes
        $settings
            .compactMap { $0 }
            .sink { [weak self] settings in
                self?.saveSettingsLocally(settings)
            }
            .store(in: &cancellables)
    }

    func loadSettings() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let cameraId = try keychain.get(Keys.cameraId)
            let fridgeName = userDefaults.string(forKey: Keys.fridgeName) ?? "My Fridge"

            if let cameraId = cameraId {
                await MainActor.run {
                    settings = AppSettings(
                        cameraId: cameraId,
                        fridgeName: fridgeName,
                        refreshInterval: 0,
                        notificationsEnabled: false
                    )
                    isSetupComplete = userDefaults.bool(forKey: Keys.setupComplete)
                }
            } else {
                await MainActor.run {
                    isSetupComplete = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load settings: \(error.localizedDescription)"
                isSetupComplete = false
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    func saveSettings(_ newSettings: AppSettings) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            try keychain.set(newSettings.cameraId, key: Keys.cameraId)
            userDefaults.set(newSettings.fridgeName, forKey: Keys.fridgeName)

            await MainActor.run {
                settings = newSettings
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save settings: \(error.localizedDescription)"
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func saveSettingsLocally(_ settings: AppSettings) {
        userDefaults.set(settings.fridgeName, forKey: Keys.fridgeName)
    }

    func updateFridgeName(_ newName: String) async {
        guard var currentSettings = settings else { return }

        let updatedSettings = AppSettings(
            cameraId: currentSettings.cameraId,
            fridgeName: newName,
            refreshInterval: currentSettings.refreshInterval,
            notificationsEnabled: currentSettings.notificationsEnabled
        )

        await saveSettings(updatedSettings)
    }

    func saveAPIKey(_ apiKey: String) async {
        do {
            try keychain.set(apiKey, key: Keys.apiKey)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save API key: \(error.localizedDescription)"
            }
        }
    }

    func getAPIKey() async -> String? {
        do {
            return try keychain.get(Keys.apiKey)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to retrieve API key: \(error.localizedDescription)"
            }
            return nil
        }
    }

    func saveUserInfo(email: String, userId: String) async {
        do {
            try keychain.set(email, key: Keys.userEmail)
            try keychain.set(userId, key: Keys.userId)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save user info: \(error.localizedDescription)"
            }
        }
    }

    func getUserInfo() async -> (email: String?, userId: String?) {
        do {
            let email = try keychain.get(Keys.userEmail)
            let userId = try keychain.get(Keys.userId)
            return (email, userId)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to retrieve user info: \(error.localizedDescription)"
            }
            return (nil, nil)
        }
    }

    func completeSetup() {
        userDefaults.set(true, forKey: Keys.setupComplete)
        isSetupComplete = true
    }

    func resetCamera() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            try keychain.remove(Keys.cameraId)
            try keychain.remove(Keys.apiKey)
            userDefaults.removeObject(forKey: Keys.fridgeName)
            userDefaults.removeObject(forKey: Keys.setupComplete)

            await MainActor.run {
                settings = nil
                isSetupComplete = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to reset camera: \(error.localizedDescription)"
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    func logout() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // Remove all stored data
            try keychain.removeAll()
            userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

            await MainActor.run {
                settings = nil
                isSetupComplete = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to logout: \(error.localizedDescription)"
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    func clearError() {
        errorMessage = nil
    }
}