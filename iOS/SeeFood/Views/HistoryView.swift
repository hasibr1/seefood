import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var imageCacheService: ImageCacheService
    @State private var selectedImage: FridgeImage?
    @State private var showingImageDetail = false
    @State private var searchText = ""
    @State private var showingDatePicker = false
    @State private var dateFilterStart: Date?
    @State private var dateFilterEnd: Date?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isEmpty {
                    emptyStateView
                } else {
                    searchAndFilterView

                    if searchText.isEmpty && !hasDateFilter {
                        groupedHistoryView
                    } else {
                        filteredHistoryView
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshHistory()
            }
            .onAppear {
                viewModel.loadHistory()
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
                    HistoryImageDetailView(image: selectedImage)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                dateFilterView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.seeFoodGray)

            Text(viewModel.emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Capture First Image") {
                // Navigate to main fridge tab
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                    tabBarController.selectedIndex = 0
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchAndFilterView: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search by date...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            // Filter Buttons
            HStack {
                Button(action: {
                    showingDatePicker = true
                }) {
                    HStack {
                        Image(systemName: hasDateFilter ? "calendar.fill" : "calendar")
                        Text(hasDateFilter ? "Filtering" : "Filter")
                    }
                    .font(.caption)
                    .foregroundColor(hasDateFilter ? .white : .seeFoodBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(hasDateFilter ? Color.seeFoodBlue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.seeFoodBlue, lineWidth: 1)
                    )
                }

                Spacer()

                if hasDateFilter {
                    Button("Clear Filter") {
                        dateFilterStart = nil
                        dateFilterEnd = nil
                    }
                    .font(.caption)
                    .foregroundColor(.seeFoodRed)
                }

                Spacer()

                // Statistics
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(viewModel.imagesTodayCount) today")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("\(viewModel.totalImages) total")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var groupedHistoryView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.groupedImages(), id: \.date) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Date Header
                        Text(viewModel.dateHeader(for: group.date))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        // Image Grid
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(group.images) { image in
                                HistoryImageItemView(
                                    image: image,
                                    onTap: {
                                        selectedImage = image
                                        showingImageDetail = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Load More Button
                if viewModel.hasMoreImages {
                    loadMoreButton
                } else if !viewModel.images.isEmpty {
                    endOfHistoryView
                }
            }
            .padding(.vertical)
        }
    }

    private var filteredHistoryView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredImages) { image in
                    HistoryImageItemView(
                        image: image,
                        onTap: {
                            selectedImage = image
                            showingImageDetail = true
                        }
                    )
                }
            }
            .padding()
        }
    }

    private var filteredImages: [FridgeImage] {
        var images = viewModel.images

        // Apply search filter
        if !searchText.isEmpty {
            images = viewModel.searchImages(text: searchText)
        }

        // Apply date filter
        if let start = dateFilterStart, let end = dateFilterEnd {
            images = viewModel.filterImagesByDateRange(from: start, to: end)
        }

        return images
    }

    private var hasDateFilter: Bool {
        return dateFilterStart != nil || dateFilterEnd != nil
    }

    private var loadMoreButton: some View {
        HStack {
            if viewModel.isLoadingMore {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading more...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Button("Load More") {
                    viewModel.loadMoreImages()
                }
                .font(.caption)
                .foregroundColor(.seeFoodBlue)
            }
        }
        .padding()
    }

    private var endOfHistoryView: some View {
        VStack(spacing: 8) {
            Text("End of History")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Showing last 24 hours")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var dateFilterView: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Start Date")
                        .font(.headline)

                    DatePicker("From", selection: Binding(
                        get: { dateFilterStart ?? Date() },
                        set: { dateFilterStart = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("End Date")
                        .font(.headline)

                    DatePicker("To", selection: Binding(
                        get: { dateFilterEnd ?? Date() },
                        set: { dateFilterEnd = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Date Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingDatePicker = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        showingDatePicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct HistoryImageItemView: View {
    let image: FridgeImage
    let onTap: () -> Void
    @EnvironmentObject var imageCacheService: ImageCacheService
    @State private var cachedImage: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Image or Placeholder
                Group {
                    if let cachedImage = cachedImage {
                        Image(uiImage: cachedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        AsyncImage(url: image.thumbnailURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .onAppear {
                                    Task {
                                        self.cachedImage = await imageCacheService.getCachedThumbnail(for: image)
                                    }
                                }
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.5)
                                )
                        }
                    }
                }
                .clipped()
                .cornerRadius(8)

                // Time Overlay
                VStack {
                    HStack {
                        Spacer()
                        Text(image.capturedAt.timeAgoDisplay())
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            .padding(4)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            onTap()
        }
    }
}

struct HistoryImageDetailView: View {
    let image: FridgeImage
    @EnvironmentObject var imageCacheService: ImageCacheService
    @Environment(\.dismiss) private var dismiss
    @State private var fullSizeImage: UIImage?
    @State private var isLoadingImage = true

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if let fullSizeImage = fullSizeImage {
                    Image(uiImage: fullSizeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("Loading full image...")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Share Image") {
                            // Share functionality would go here
                        }

                        Button("Save to Photos") {
                            // Save to photos functionality would go here
                        }

                        Button("Delete", role: .destructive) {
                            // Delete functionality would go here
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadFullImage()
        }
    }

    private func loadFullImage() {
        Task {
            do {
                let image = try await imageCacheService.loadImage(from: image.imageURL, id: image.id)
                await MainActor.run {
                    self.fullSizeImage = image
                    isLoadingImage = false
                }
            } catch {
                await MainActor.run {
                    isLoadingImage = false
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(SettingsService())
        .environmentObject(ImageCacheService())
}