import SwiftUI
import AVFoundation

// MARK: - Scan sheet (camera + manual entry + lookup states)

struct BarcodeScanSheet: View {
    let onFound: (FoodItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading  = false
    @State private var errorText: String?
    @State private var manualCode = ""
    @State private var showManual = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                BarcodeCameraView { code in handle(code) }
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Viewfinder
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.sbAccent, lineWidth: 3)
                        .frame(width: 260, height: 150)

                    Text("Point the camera at the barcode")
                        .font(SBFont.caption())
                        .foregroundColor(.white)
                        .padding(.top, 14)
                        .shadow(radius: 4)

                    Spacer()

                    if let errorText {
                        Text(errorText)
                            .font(SBFont.caption())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .background(Color.sbRed.opacity(0.85))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                    }

                    // Manual entry
                    VStack(spacing: 10) {
                        if showManual {
                            HStack(spacing: 10) {
                                TextField("Barcode number", text: $manualCode)
                                    .keyboardType(.numberPad)
                                    .font(SBFont.body())
                                    .foregroundColor(.sbTextPrimary)
                                    .padding(12)
                                    .background(Color.sbSurface)
                                    .cornerRadius(12)

                                Button {
                                    guard manualCode.count >= 6 else { return }
                                    handle(manualCode)
                                } label: {
                                    Text("Search")
                                        .font(SBFont.caption())
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 13)
                                        .background(Color.sbAccent)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            Button {
                                withAnimation { showManual = true }
                            } label: {
                                Text("Enter barcode manually")
                                    .font(SBFont.caption())
                                    .foregroundColor(.white)
                                    .underline()
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }

                if isLoading {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                }
            }
            .navigationTitle(Text("Scan Barcode"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.sbAccent)
                }
            }
        }
    }

    private func handle(_ code: String) {
        guard !isLoading else { return }
        HapticManager.light()
        isLoading = true
        errorText = nil
        Task { @MainActor in
            do {
                let item = try await OpenFoodFactsService.shared.lookup(barcode: code)
                HapticManager.success()
                onFound(item)
                dismiss()
            } catch {
                HapticManager.error()
                errorText = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Camera wrapper

private struct BarcodeCameraView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeCameraController {
        let vc = BarcodeCameraController()
        vc.onScan = onScan
        return vc
    }

    func updateUIViewController(_ vc: BarcodeCameraController, context: Context) {}
}

final class BarcodeCameraController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastCode: String?
    private var lastScanTime: Date = .distantPast

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?.configureSession() }
            }
        default:
            break  // Denied — the sheet still offers manual entry.
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean13, .ean8, .upce, .code128]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        startSession()
    }

    private func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let code = obj.stringValue else { return }
        // Suppress rapid duplicate reads, but allow rescanning the same
        // product after a few seconds (e.g. after a "not found" error).
        if code == lastCode && Date().timeIntervalSince(lastScanTime) < 3 { return }
        lastCode = code
        lastScanTime = Date()
        onScan?(code)
    }
}
