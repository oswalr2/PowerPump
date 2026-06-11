import SwiftUI
import PhotosUI

struct FoodScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var foodLog = FoodLogStore.shared
    private let service = ClaudeVisionService.shared

    @State private var phase: ScanPhase = .idle
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var loggedToast = false

    enum ScanPhase {
        case idle
        case analyzing(UIImage)
        case results(UIImage, FoodScanResponse)
        case error(String)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                switch phase {
                case .idle:           idleView
                case .analyzing(let img): analyzingView(img)
                case .results(let img, let res): resultsView(img, res)
                case .error(let msg): errorView(msg)
                }

                // Logged toast
                if loggedToast {
                    VStack {
                        Spacer()
                        Label("Added to food log!", systemImage: "checkmark.circle.fill")
                            .font(SBFont.body())
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.sbGreen)
                            .cornerRadius(20)
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Scan Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundColor(.sbAccent)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView { image in
                    capturedImage = image
                    showCamera = false
                    if let img = image { startAnalysis(img) }
                }
            }
            .onChange(of: selectedPhoto) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        startAnalysis(img)
                    }
                }
            }
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(Color.sbAccentDim)
                    .frame(width: 120, height: 120)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.sbAccent)
            }

            VStack(spacing: 10) {
                Text("AI Food Scanner")
                    .font(SBFont.display(26))
                    .foregroundColor(.sbTextPrimary)
                Text("Take a photo of your meal and Claude\nwill estimate the calories and macros.")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Scan limit indicator
            scanLimitBadge

            Spacer()

            if service.isLimitReached {
                limitReachedCard
            } else {
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        HapticManager.medium()
                        showCamera = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Take a Photo")
                                .font(SBFont.body())
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.sbAccent)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Choose from Library")
                                .font(SBFont.body())
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.sbAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.sbAccentDim)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbAccent.opacity(0.4), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 40)
        }
    }

    private var scanLimitBadge: some View {
        HStack(spacing: 6) {
            ForEach(0..<Config.weeklyScanLimit, id: \.self) { i in
                Circle()
                    .fill(i < service.scansUsedThisWeek ? Color.sbBorder : Color.sbAccent)
                    .frame(width: 10, height: 10)
            }
            Text(service.scansRemaining == 1
                 ? "1 scan left this week"
                 : "\(service.scansRemaining) scans left this week")
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .padding(.leading, 4)
        }
    }

    private var limitReachedCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 32))
                .foregroundColor(.sbTextSecondary)
            Text("Weekly limit reached")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)
            Text("You've used your free scan for this week.\nCome back next week for more!")
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color.sbSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.sbBorder))
        .padding(.horizontal, 24)
    }

    // MARK: - Analyzing

    private func analyzingView(_ image: UIImage) -> some View {
        VStack(spacing: 28) {
            Spacer()

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.sbBorder, lineWidth: 1)
                )

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.sbAccent)
                Text("Analyzing your meal…")
                    .font(SBFont.heading(16))
                    .foregroundColor(.sbTextPrimary)
                Text("Claude is identifying foods and estimating nutrition")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Results

    private func resultsView(_ image: UIImage, _ result: FoodScanResponse) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Photo thumbnail
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Total summary card
                HStack(spacing: 0) {
                    totalStat("\(result.totalCalories)", "kcal", "Calories")
                    Divider().frame(height: 40)
                    totalStat(formatMacro(result.totalProtein), "g", "Protein")
                    Divider().frame(height: 40)
                    totalStat(formatMacro(result.totalCarbs), "g", "Carbs")
                    Divider().frame(height: 40)
                    totalStat(formatMacro(result.totalFat), "g", "Fat")
                }
                .background(Color.sbSurface)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
                .padding(.horizontal, 20)

                // Individual items
                if result.items.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 32))
                            .foregroundColor(.sbTextSecondary)
                        Text("No food detected")
                            .font(SBFont.heading())
                            .foregroundColor(.sbTextPrimary)
                        Text("Try a clearer or closer photo")
                            .font(SBFont.body())
                            .foregroundColor(.sbTextSecondary)
                    }
                    .padding(32)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Detected items")
                            .font(SBFont.heading())
                            .foregroundColor(.sbTextPrimary)
                            .padding(.horizontal, 20)

                        ForEach(result.items) { item in
                            ScannedItemRow(item: item)
                        }
                    }
                }

                // Log button
                if !result.items.isEmpty {
                    Button {
                        logAll(result)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add All to Food Log")
                        }
                        .font(SBFont.body())
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.sbAccent)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }

                // Scan again
                Button {
                    withAnimation(.spring(response: 0.35)) { phase = .idle }
                } label: {
                    Text("Scan Another Meal")
                        .font(SBFont.body())
                        .foregroundColor(.sbAccent)
                }

                Spacer(minLength: 40)
            }
        }
    }

    private func totalStat(_ value: String, _ unit: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(SBFont.heading(17))
                    .foregroundColor(.sbTextPrimary)
                    .monospacedDigit()
                Text(unit)
                    .font(SBFont.label(10))
                    .foregroundColor(.sbTextSecondary)
            }
            Text(label)
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.sbRed)
            Text("Something went wrong")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)
            Text(message)
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                withAnimation { phase = .idle }
            } label: {
                Text("Try Again")
                    .font(SBFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.sbAccent)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Actions

    private func startAnalysis(_ image: UIImage) {
        withAnimation(.spring(response: 0.35)) { phase = .analyzing(image) }
        Task {
            do {
                let result = try await service.analyzeFood(image: image)
                withAnimation(.spring(response: 0.4)) { phase = .results(image, result) }
                HapticManager.success()
            } catch {
                withAnimation(.spring(response: 0.35)) {
                    phase = .error(error.localizedDescription)
                }
                HapticManager.error()
            }
        }
    }

    private func logAll(_ result: FoodScanResponse) {
        for item in result.items {
            let g = item.grams > 0 ? item.grams : 100.0
            let food = FoodItem(
                id: UUID().uuidString,
                name: item.name,
                category: .other,
                per100g: NutritionInfo(
                    calories: Double(item.calories) / g * 100,
                    protein:  item.protein / g * 100,
                    carbs:    item.carbs   / g * 100,
                    fat:      item.fat     / g * 100
                )
            )
            foodLog.add(food, grams: g, meal: .lunch)
        }
        HapticManager.success()
        withAnimation(.spring(response: 0.35)) { loggedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { loggedToast = false }
            dismiss()
        }
    }

    private func formatMacro(_ value: Double) -> String {
        String(format: "%.0f", value)
    }
}

// MARK: - Scanned Item Row

private struct ScannedItemRow: View {
    let item: ScannedFoodItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.sbAccentDim)
                    .frame(width: 44, height: 44)
                Image(systemName: "fork.knife")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.sbAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(SBFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(.sbTextPrimary)
                HStack(spacing: 8) {
                    Text("\(Int(item.grams))g")
                        .foregroundColor(.sbTextSecondary)
                    Text("·")
                        .foregroundColor(.sbBorder)
                    Text("\(item.calories) kcal")
                        .foregroundColor(.sbTextSecondary)
                }
                .font(SBFont.caption())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                macroTag("P", "\(Int(item.protein))g", .sbAccent)
                macroTag("C", "\(Int(item.carbs))g", .sbGreen)
            }
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
        .padding(.horizontal, 20)
    }

    private func macroTag(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(SBFont.label(10))
                .foregroundColor(color)
            Text(value)
                .font(SBFont.label(10))
                .fontWeight(.semibold)
                .foregroundColor(.sbTextPrimary)
        }
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper)

struct CameraPickerView: UIViewControllerRepresentable {
    let onImage: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage?) -> Void
        init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onImage(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImage(nil)
        }
    }
}
