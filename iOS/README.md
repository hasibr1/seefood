# SeeFood iOS App

A native iOS app that allows users to view food items in their fridge through an installed camera system. The app provides real-time or periodic images from inside the fridge, with potential for food identification and inventory management features.

## Features

### MVP Features
- **Main Fridge View** - Display latest camera image with pull-to-refresh
- **Manual Refresh** - Capture new images on demand
- **Timestamp Display** - Show when image was captured
- **Connection Status** - Camera online/offline indicator
- **Basic Settings** - Camera connection configuration
- **Image History** - View last 24 hours of images in a grid layout
- **QR Code Setup** - Easy camera setup with QR code scanning

### Technical Features
- Native iOS app built with SwiftUI
- MVVM architecture with Combine framework
- Image caching for offline viewing
- Secure API key storage using Keychain
- Camera status monitoring
- Pull-to-refresh functionality
- Lazy loading for image history
- Comprehensive error handling

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+
- SeeFood camera hardware

## Installation

### Using Xcode

1. Clone the repository:
```bash
git clone <repository-url>
cd seefood/iOS
```

2. Open `SeeFood.xcodeproj` in Xcode

3. Build and run the project on a simulator or physical device

### Dependencies

The app uses Swift Package Manager for dependency management:

- **KeychainAccess** - Secure storage for API keys and sensitive data

## Architecture

### Project Structure
```
SeeFood/
├── App/
│   ├── SeeFoodApp.swift          # Main app entry point
│   └── ContentView.swift         # Root view and onboarding
├── Views/
│   ├── FridgeView.swift          # Main camera display
│   ├── HistoryView.swift         # Image history grid
│   └── SettingsView.swift        # Settings and configuration
├── ViewModels/
│   ├── FridgeViewModel.swift     # Main view logic
│   ├── HistoryViewModel.swift    # History management
│   └── SettingsViewModel.swift   # Settings logic
├── Models/
│   ├── FridgeImage.swift         # Image data model
│   ├── CameraStatus.swift        # Camera status model
│   └── AppSettings.swift         # App configuration model
├── Services/
│   ├── CameraService.swift       # API communication
│   ├── ImageCacheService.swift   # Image caching
│   └── SettingsService.swift     # Local storage
└── Utils/
    ├── Constants.swift           # App constants
    └── Extensions.swift          # Utility extensions
```

### MVVM Architecture

The app follows the Model-View-ViewModel pattern:

- **Models**: Data structures that represent the app's domain (FridgeImage, CameraStatus, etc.)
- **Views**: SwiftUI views that display the UI and handle user interactions
- **ViewModels**: Business logic that coordinates between models and views using Combine

### Key Components

#### CameraService
- Handles all API communication with the backend
- Manages camera setup, image capture, and status checking
- Implements retry logic and error handling

#### ImageCacheService
- Manages local image caching for offline viewing
- Implements memory-efficient image loading
- Automatic cache cleanup to manage storage

#### SettingsService
- Manages app settings and user preferences
- Secure storage of API keys using Keychain
- Handles user authentication and camera setup state

## API Integration

The iOS app integrates with a Next.js backend that provides the following endpoints:

### Authentication
- `POST /api/auth/register` - Create user account
- `POST /api/auth/login` - Authenticate user

### Camera Management
- `POST /api/cameras/connect` - Exchange QR setup token for API key
- `POST /api/cameras/test` - Test camera connectivity
- `GET /api/cameras/{camera_id}/status` - Check camera status

### Image Management
- `POST /api/cameras/{camera_id}/capture` - Request new image capture
- `GET /api/cameras/{camera_id}/latest` - Get most recent image
- `GET /api/cameras/{camera_id}/history` - Get image history

## Setup Process

1. **Onboarding** - User is greeted with setup instructions
2. **QR Code Scanning** - User scans QR code on camera device
3. **Connection Test** - App verifies camera connectivity
4. **Fridge Naming** - User can personalize their fridge name
5. **Success** - Setup complete and app is ready to use

## Configuration

### API Endpoints
Update the base URL in `Constants.swift` to point to your backend:

```swift
struct Constants {
    struct API {
        static let baseURL = "https://your-api-domain.com"
        // ...
    }
}
```

### Bundle Identifier
Update the bundle identifier in the Xcode project settings:
- Target: SeeFood
- Bundle Identifier: `com.yourcompany.seefood`

## Security

- API keys are stored securely in the iOS Keychain
- All API communication uses HTTPS
- Setup tokens expire after 30 minutes
- Camera authentication uses one-time setup tokens

## Testing

### Unit Tests
Run unit tests to verify ViewModel logic and service functionality:

```bash
xcodebuild test -scheme SeeFood -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Manual Testing
Key features to test manually:
- QR code scanning and camera setup
- Image capture and display
- History view navigation
- Settings updates
- Offline behavior with cached images

## Performance

### Image Caching
- Images are cached locally for offline viewing
- Memory cache limits prevent excessive RAM usage
- Disk cache automatically cleans up old images
- Cache size is configurable in Constants.swift

### Network Optimization
- Thumbnails are loaded first for better perceived performance
- Full-size images are loaded on-demand
- Retry logic handles network failures gracefully
- Request timeouts prevent hanging operations

## Troubleshooting

### Common Issues

**Camera won't connect**
- Verify QR code is valid and not expired
- Check network connectivity
- Ensure backend API is accessible

**Images not loading**
- Check API key is valid
- Verify network connectivity
- Check image cache size and clear if needed

**QR code scanning not working**
- Ensure camera permissions are granted
- Check lighting conditions
- Verify QR code is not damaged

### Debug Information
The app includes diagnostic information export feature in Settings:
- App version and build number
- Camera connection status
- Cache size and user information
- System information

## Future Enhancements

Planned features for future releases:
- Automatic food detection using Vision framework
- Inventory management with manual tagging
- Expiration date tracking
- Push notifications for low stock alerts
- Multiple fridge/camera support
- Recipe suggestions based on available ingredients
- Apple Watch companion app
- Food waste analytics and reporting

## License

This project is proprietary and confidential.

## Support

For support and questions:
- Email: support@seefood.app
- Documentation: https://docs.seefood.app