import SwiftUI

struct FridgeView: View {
    @StateObject private var viewModel = FridgeViewModel()
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var imageCacheService: ImageCacheService
    @State private var showingImageDetail = false
    @State private var selectedImage: UIImage?
    @State private var refreshTask: Task<Void, Never>?

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if let settings = settingsService.settings {
                    VStack(spacing: 0) {
                        // Status Bar
                        statusBarView

                        // Main Image Display
                        mainImageView

                        // Refresh Controls
                        refreshControlsView
                    }
                } else {
                    // Setup required view
                    setupRequiredView
                }
            }
            .navigationTitle("My Fridge")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.handlePullToRefresh()
            }
            .onAppear {
                viewModel.loadInitialData()
            }
            .onDisappear {
                refreshTask?.cancel()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showingImageDetail) {
                if let selectedImage = selectedImage {
                    ImageDetailView(image: selectedImage)
                }
            }
        }
    }

    private var setupRequiredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "refrigerator")
                .font(.system(size: 80))
                .foregroundColor(.seeFoodGray)

            Text("No Camera Setup")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Go to Settings to set up your SeeFood camera")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Go to Settings") {
                // Navigate to settings tab
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                    tabBarController.selectedIndex = 2
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var statusBarView: some View {
        HStack {
            // Connection Status
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isCameraOnline ? Color.seeFoodGreen : Color.seeFoodRed)
                    .frame(width: 8, height: 8)

                Text(viewModel.isCameraOnline ? "Online" : "Offline")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.isCameraOnline ? .seeFoodGreen : .seeFoodRed)
            }

            Spacer()

            // Last Capture Time
            if let lastCapture = viewModel.cameraStatus?.lastCapture {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last capture")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(lastCapture.timeAgoDisplay())
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private var mainImageView: some View {
        GeometryReader { geometry in
            ZStack {
                // Placeholder or Loading State
                if viewModel.currentImage == nil {
                    placeholderView(geometry: geometry)
                } else {
                    // Actual Image
                    AsyncImage(url: viewModel.currentImage?.imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                            .clipped()
                            .onTapGesture {
                                loadFullImageForDisplay()
                            }
                    } placeholder: {
                        loadingView(geometry: geometry)
                    }
                }

                // Loading Overlay
                if viewModel.isRefreshing || viewModel.isLoading {
                    loadingOverlay
                }

                // Timestamp Overlay
                if let currentImage = viewModel.currentImage {
                    timestampOverlay(image: currentImage)
                }
            }
        }
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func placeholderView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "camera")
                .font(.system(size: 40))
                .foregroundColor(.seeFoodGray)

            Text("No images yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Pull down to capture your first image")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
        .frame(height: geometry.size.height)
    }

    private func loadingView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading image...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
        .frame(height: geometry.size.height)
    }

    private var loadingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)

            Text(viewModel.isRefreshing ? "Capturing..." : "Loading...")
                .font(.body)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .frame(width: 120, height: 120)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }

    private func timestampOverlay(image: FridgeImage) -> some View {
        VStack {
            HStack {
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(image.capturedAt.formatForDisplay())
                        .font(.caption)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                    Text("File size: \(ByteCountFormatter.string(fromByteCount: image.fileSize, countStyle: .file))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .padding(8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .padding(12)
            }
            Spacer()
        }
    }

    private var refreshControlsView: some View {
        VStack(spacing: 16) {
            // Refresh Button
            Button(action: {
                refreshTask = Task {
                    await viewModel.refreshImage()
                }
            }) {
                HStack {
                    Image(systemName: viewModel.isRefreshing ? "camera.fill" : "camera")
                        .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                        .animation(viewModel.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isRefreshing)

                    Text(viewModel.isRefreshing ? "Capturing..." : "Capture New Image")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.isRefreshing ? Color.gray : Color.seeFoodBlue)
                .cornerRadius(12)
            }
            .disabled(viewModel.isRefreshing || !viewModel.isCameraOnline)

            // Status Text
            if let statusText = viewModel.refreshText as String? {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            // Camera Info
            if let batteryLevel = viewModel.batteryLevelText,
               let signalStrength = viewModel.signalStrengthText {
                HStack {
                    Label(batteryLevel, systemImage: "battery.100")
                    Spacer()
                    Label(signalStrength, systemImage: "antenna.radiowaves.left.and.right")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal)
    }

    private func loadFullImageForDisplay() {
        guard let currentImage = viewModel.currentImage else { return }

        Task {
            if let image = await viewModel.loadImage() {
                await MainActor.run {
                    selectedImage = image
                    showingImageDetail = true
                }
            }
        }
    }
}

struct ImageDetailView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = max(0.5, min(scale * delta, 5.0))
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1.0 {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            scale = 1.0
                                            offset = .zero
                                        }
                                    }
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    FridgeView()
        .environmentObject(SettingsService())
        .environmentObject(ImageCacheService())
}