# SeeFood

A comprehensive smart fridge monitoring system that allows users to see the food in their fridge through an iOS app. The system includes a backend API server and a native iOS application.

## Overview

SeeFood consists of two main components:

1. **Backend API** (Next.js) - Handles authentication, camera management, and image storage
2. **iOS App** (Swift/SwiftUI) - Native mobile app for viewing fridge contents

## Features

### Backend API (Next.js)
- User authentication and management
- Camera setup via QR code authentication
- Image capture and storage API
- Camera status monitoring
- RESTful API endpoints for iOS app integration

### iOS App
- Real-time fridge camera viewing
- Pull-to-refresh image capture
- 24-hour image history with lazy loading
- QR code camera setup
- Offline image caching
- Camera status monitoring
- Settings and configuration management

## Architecture

### Backend Structure
```
seefood/
├── src/app/api/
│   ├── auth/                    # User authentication
│   │   ├── register/
│   │   └── login/
│   ├── cameras/                 # Camera management
│   │   ├── connect/            # QR code setup
│   │   ├── test/               # Camera connectivity
│   │   └── [camera_id]/        # Dynamic camera operations
│   │       ├── status/         # Camera status
│   │       ├── capture/        # Image capture
│   │       ├── latest/         # Latest image
│   │       └── history/        # Image history
│   └── user/
│       └── profile/            # User profile
└── iOS/                        # Native iOS app
```

### iOS App Structure
```
iOS/SeeFood/
├── App/                        # App entry point
├── Views/                      # SwiftUI views
├── ViewModels/                 # MVVM view models
├── Models/                     # Data models
├── Services/                   # API and cache services
└── Utils/                      # Utilities and constants
```

## Getting Started

### Prerequisites
- Node.js 18+ for backend
- Xcode 15+ for iOS development
- iOS 15+ target for mobile app

### Backend Setup

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm run dev
```

3. Open [http://localhost:3000](http://localhost:3000) to access the API

The backend provides these API endpoints:
- `POST /api/auth/register` - Create user account
- `POST /api/auth/login` - Authenticate user
- `POST /api/cameras/connect` - Connect camera via QR code
- `POST /api/cameras/test` - Test camera connectivity
- `GET /api/cameras/{camera_id}/status` - Check camera status
- `POST /api/cameras/{camera_id}/capture` - Capture new image
- `GET /api/cameras/{camera_id}/latest` - Get latest image
- `GET /api/cameras/{camera_id}/history` - Get image history

### iOS App Setup

1. Navigate to the iOS directory:
```bash
cd iOS
```

2. Open `SeeFood.xcodeproj` in Xcode

3. Build and run the project on a simulator or physical device

4. Configure the API base URL in `iOS/SeeFood/Utils/Constants.swift`:
```swift
struct Constants {
    struct API {
        static let baseURL = "http://localhost:3000"  // Update for production
    }
}
```

## Camera Setup Flow

1. **QR Code Generation** - Camera generates a QR code with setup token
2. **iOS App Scanning** - User scans QR code with iOS app
3. **Token Exchange** - App exchanges setup token for API key
4. **Connection Test** - App tests camera connectivity
5. **Setup Complete** - Camera is ready for use

## Data Models

### FridgeImage
```swift
struct FridgeImage: Identifiable, Codable {
    let id: UUID
    let cameraId: String
    let imageURL: URL
    let thumbnailURL: URL
    let capturedAt: Date
    let fileSize: Int64
}
```

### CameraStatus
```swift
struct CameraStatus: Codable {
    let cameraId: String
    let isOnline: Bool
    let lastCapture: Date?
    let batteryLevel: Float?
    let signalStrength: Int?
}
```

## Security

- JWT-based authentication for API access
- QR code tokens expire after 30 minutes
- API keys stored securely in iOS Keychain
- HTTPS-only communication in production
- Input validation and sanitization

## Performance

### Image Caching
- Local caching on iOS device for offline viewing
- Automatic cache cleanup after 7 days
- Memory-efficient image loading
- Lazy loading for image history

### Network Optimization
- Thumbnail preloading for better UX
- Retry logic with exponential backoff
- Request timeouts to prevent hanging
- Efficient data serialization

## Testing

### Backend Testing
```bash
npm test        # Run unit tests
npm run build   # Test production build
```

### iOS Testing
```bash
xcodebuild test -scheme SeeFood -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Deployment

### Backend (Vercel)
The easiest way to deploy the backend is using [Vercel](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme).

Check out the [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.

### iOS App (App Store)
1. Update bundle identifier in Xcode project settings
2. Configure code signing and provisioning profiles
3. Archive and upload to App Store Connect
4. Submit for review

## Future Enhancements

Planned features for future releases:
- Automatic food detection using Vision framework
- Inventory management with manual tagging
- Expiration date tracking and notifications
- Multiple fridge/camera support
- Recipe suggestions based on available ingredients
- Apple Watch companion app
- Food waste analytics and reporting
- Web dashboard for desktop viewing

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary and confidential.

## Support

For support and questions:
- Email: support@seefood.app
- Documentation: [iOS App README](./iOS/README.md)
- API Documentation: See API endpoint documentation above
