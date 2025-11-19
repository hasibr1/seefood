import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var imageCacheService: ImageCacheService
    @State private var showingQRScanner = false
    @State private var showingFridgeNameEdit = false
    @State private var tempFridgeName = ""

    var body: some View {
        NavigationView {
            List {
                if viewModel.isSetupComplete {
                    setupSection
                    cameraSection
                    cacheSection
                    accountSection
                    aboutSection
                } else {
                    setupRequiredSection
                    aboutSection
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshCameraStatus()
            }
            .onAppear {
                tempFridgeName = viewModel.settings.fridgeName
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
            .alert("Reset Camera", isPresented: $viewModel.showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    Task {
                        await viewModel.resetCamera()
                    }
                }
            } message: {
                Text("This will disconnect your camera and you'll need to set it up again. Are you sure?")
            }
            .alert("Logout", isPresented: $viewModel.showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    Task {
                        await viewModel.logout()
                    }
                }
            } message: {
                Text("This will log you out and remove all stored data from this device. Are you sure?")
            }
            .sheet(isPresented: $showingQRScanner) {
                QRCodeScannerView { qrData in
                    Task {
                        let success = await viewModel.handleQRCodeResult(qrData)
                        if success {
                            showingQRScanner = false
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFridgeNameEdit) {
                fridgeNameEditView
            }
        }
    }

    private var setupRequiredSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "refrigerator")
                    .font(.system(size: 50))
                    .foregroundColor(.seeFoodGray)

                Text("No Camera Setup")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Set up your SeeFood camera to start monitoring your fridge")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    showingQRScanner = true
                }) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Set Up Camera")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.seeFoodBlue)
                    .cornerRadius(12)
                }
            }
            .padding(.vertical, 20)
        }
    }

    private var setupSection: some View {
        Section("Fridge Settings") {
            HStack {
                Label("Fridge Name", systemImage: "tag.fill")
                Spacer()
                Text(viewModel.settings.fridgeName)
                    .foregroundColor(.secondary)
                Button(action: {
                    showingFridgeNameEdit = true
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            HStack {
                Label("Camera ID", systemImage: "camera.fill")
                Spacer()
                Text(viewModel.settings.cameraId)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var cameraSection: some View {
        Section("Camera Status") {
            HStack {
                Circle()
                    .fill(viewModel.isCameraOnline ? Color.seeFoodGreen : Color.seeFoodRed)
                    .frame(width: 12, height: 12)

                Text("Connection")
                Spacer()
                Text(viewModel.isCameraOnline ? "Online" : "Offline")
                    .foregroundColor(viewModel.isCameraOnline ? .seeFoodGreen : .seeFoodRed)
            }

            Button(action: {
                Task {
                    await viewModel.testCameraConnection()
                }
            }) {
                HStack {
                    Image(systemName: "network")
                    Text("Test Connection")
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(viewModel.isLoading)

            Button(action: {
                viewModel.showResetDialog()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reset Camera")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.seeFoodRed)
        }
    }

    private var cacheSection: some View {
        Section("Storage") {
            HStack {
                Label("Cache Size", systemImage: "internaldrive")
                Spacer()
                Text(viewModel.cacheSize)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                Task {
                    await viewModel.clearImageCache()
                }
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Clear Cache")
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(viewModel.isLoading)
        }
    }

    private var accountSection: some View {
        Section("Account") {
            Button(action: {
                viewModel.showLogoutDialog()
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                    Text("Logout")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.seeFoodRed)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "mailto:\(viewModel.supportEmail)")!) {
                HStack {
                    Label("Support", systemImage: "envelope.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Link(destination: URL(string: "https://seefood.app/privacy")!) {
                HStack {
                    Label("Privacy Policy", systemImage: "lock.shield")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Link(destination: URL(string: "https://seefood.app/terms")!) {
                HStack {
                    Label("Terms of Service", systemImage: "doc.text")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Label("Diagnostic Info", systemImage: "stethoscope")
                Spacer()
                Button("Export") {
                    exportDiagnosticInfo()
                }
                .font(.caption)
            }
        }
    }

    private var fridgeNameEditView: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fridge Name")
                        .font(.headline)

                    TextField("Enter fridge name", text: $tempFridgeName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)

                    Text("Give your fridge a personal name like \"Kitchen Fridge\" or \"Garage Fridge\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Edit Fridge Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        tempFridgeName = viewModel.settings.fridgeName
                        showingFridgeNameEdit = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if viewModel.isValidFridgeName(tempFridgeName) {
                            Task {
                                await viewModel.updateFridgeName(tempFridgeName)
                                showingFridgeNameEdit = false
                            }
                        }
                    }
                    .disabled(!viewModel.isValidFridgeName(tempFridgeName))
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func exportDiagnosticInfo() {
        Task {
            let diagnosticData = await viewModel.getDiagnosticInfo()
            let jsonString = try? JSONSerialization.data(withJSONObject: diagnosticData, options: .prettyPrinted)

            if let data = jsonString,
               let string = String(data: data, encoding: .utf8) {
                let activityViewController = UIActivityViewController(
                    activityItems: [string],
                    applicationActivities: nil
                )

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(activityViewController, animated: true)
                }
            }
        }
    }
}

// MARK: - QR Code Scanner View

struct QRCodeScannerView: UIViewControllerRepresentable {
    var onQRCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let scanner = QRCodeScannerViewController()
        scanner.onQRCodeScanned = onQRCodeScanned
        return scanner
    }

    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {}
}

class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onQRCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }

    private func setupCamera() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("No camera available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)

            captureSession = AVCaptureSession()
            captureSession?.addInput(input)

            let output = AVCaptureMetadataOutput()
            captureSession?.addOutput(output)

            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer?.frame = view.layer.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer!)

            captureSession?.startRunning()

        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    private func setupUI() {
        // Add overlay UI elements
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add scanning frame
        let scanningFrame = UIView()
        scanningFrame.layer.borderColor = UIColor.white.cgColor
        scanningFrame.layer.borderWidth = 2
        scanningFrame.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(scanningFrame)

        NSLayoutConstraint.activate([
            scanningFrame.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            scanningFrame.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            scanningFrame.widthAnchor.constraint(equalToConstant: 250),
            scanningFrame.heightAnchor.constraint(equalToConstant: 250)
        ])

        // Add instructions label
        let instructionLabel = UILabel()
        instructionLabel.text = "Scan the QR code on your SeeFood camera"
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(instructionLabel)

        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: scanningFrame.bottomAnchor, constant: 30),
            instructionLabel.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -20)
        ])

        // Add cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        cancelButton.layer.cornerRadius = 8
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        overlayView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Add corner markers
        addCornerMarkers(to: overlayView)
    }

    private func addCornerMarkers(to view: UIView) {
        let markerSize: CGFloat = 20
        let markerColor = UIColor.white
        let markerWidth: CGFloat = 3

        let positions = [
            (CGPoint(x: -100, y: -100), .topLeft),
            (CGPoint(x: 100, y: -100), .topRight),
            (CGPoint(x: -100, y: 100), .bottomLeft),
            (CGPoint(x: 100, y: 100), .bottomRight)
        ]

        for (offset, corner) in positions {
            let markerView = UIView()
            markerView.backgroundColor = .clear
            markerView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(markerView)

            NSLayoutConstraint.activate([
                markerView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset.x),
                markerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset.y),
                markerView.widthAnchor.constraint(equalToConstant: markerSize),
                markerView.heightAnchor.constraint(equalToConstant: markerSize)
            ])

            // Create corner path
            let path = UIBezierPath()
            switch corner {
            case .topLeft:
                path.move(to: CGPoint(x: markerSize, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: markerSize))
            case .topRight:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: markerSize, y: 0))
                path.addLine(to: CGPoint(x: markerSize, y: markerSize))
            case .bottomLeft:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: markerSize, y: 0))
                path.addLine(to: CGPoint(x: 0, y: markerSize))
            case .bottomRight:
                path.move(to: CGPoint(x: 0, y: markerSize))
                path.addLine(to: CGPoint(x: markerSize, y: markerSize))
                path.addLine(to: CGPoint(x: markerSize, y: 0))
            }

            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.strokeColor = markerColor.cgColor
            shapeLayer.lineWidth = markerWidth
            shapeLayer.fillColor = UIColor.clear.cgColor
            markerView.layer.addSublayer(shapeLayer)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else { return }

        // Handle the scanned QR code
        onQRCodeScanned?(stringValue)

        // Stop the session and dismiss
        captureSession?.stopRunning()
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        captureSession?.stopRunning()
        dismiss(animated: true)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsService())
        .environmentObject(ImageCacheService())
}