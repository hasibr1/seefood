import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsService: SettingsService
    @State private var selectedTab = 0
    @State private var showingOnboarding = false

    var body: some View {
        Group {
            if settingsService.isSetupComplete {
                TabView(selection: $selectedTab) {
                    FridgeView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Fridge")
                        }
                        .tag(0)

                    HistoryView()
                        .tabItem {
                            Image(systemName: "clock.fill")
                            Text("History")
                        }
                        .tag(1)

                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .tag(2)
                }
                .accentColor(.seeFoodBlue)
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            checkSetupStatus()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
        }
    }

    private func checkSetupStatus() {
        // This will be handled by the SettingsService automatically
        // The view will update based on the isSetupComplete property
    }
}

struct OnboardingView: View {
    @EnvironmentObject var settingsService: SettingsService
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingWelcomeView()
                .tag(0)

            OnboardingQRCodeView()
                .tag(1)

            OnboardingSuccessView()
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .ignoresSafeArea(edges: .bottom)
    }
}

struct OnboardingWelcomeView: View {
    @State private var animateTitle = false
    @State private var animateSubtitle = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "refrigerator.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.seeFoodBlue)
                    .scaleEffect(animateTitle ? 1.0 : 0.8)

                VStack(spacing: 10) {
                    Text("Welcome to SeeFood")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .opacity(animateTitle ? 1.0 : 0.0)

                    Text("See what's in your fridge from anywhere")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateSubtitle ? 1.0 : 0.0)
                }
            }

            Spacer()

            VStack(spacing: 20) {
                OnboardingStep(
                    icon: "camera.fill",
                    title: "Install Camera",
                    description: "Place your SeeFood camera inside your fridge"
                )

                OnboardingStep(
                    icon: "qrcode",
                    title: "Scan QR Code",
                    description: "Connect your camera with a simple scan"
                )

                OnboardingStep(
                    icon: "iphone",
                    title: "View Anywhere",
                    description: "Check your fridge contents from your phone"
                )
            }

            Spacer()
        }
        .padding(.horizontal, 30)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateTitle = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                animateSubtitle = true
            }
        }
    }
}

struct OnboardingStep: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.seeFoodBlue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct OnboardingQRCodeView: View {
    @EnvironmentObject var settingsService: SettingsService
    @State private var showingScanner = false
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "qrcode")
                    .font(.system(size: 60))
                    .foregroundColor(.seeFoodBlue)

                VStack(spacing: 10) {
                    Text("Connect Your Camera")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Scan the QR code on your SeeFood camera to connect it to your app")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }

            Spacer()

            VStack(spacing: 20) {
                Button(action: {
                    showingScanner = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Scan QR Code")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.seeFoodBlue)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)

                if isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Connecting camera...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 30)
        .sheet(isPresented: $showingScanner) {
            QRCodeScannerView { qrData in
                Task {
                    isProcessing = true
                    await handleQRCode(qrData)
                }
            }
        }
    }

    private func handleQRCode(_ qrData: String) async {
        // Handle QR code processing
        // This will be implemented in the CameraService
        showingScanner = false
        isProcessing = false
    }
}

struct OnboardingSuccessView: View {
    @EnvironmentObject var settingsService: SettingsService
    @State private var animateCheckmark = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.seeFoodGreen)
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.8)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }

                VStack(spacing: 10) {
                    Text("All Set Up!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Your SeeFood camera is connected and ready to use")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }

            Spacer()

            Button(action: {
                settingsService.completeSetup()
            }) {
                Text("Start Using SeeFood")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.seeFoodBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
                animateCheckmark = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsService())
        .environmentObject(ImageCacheService())
}