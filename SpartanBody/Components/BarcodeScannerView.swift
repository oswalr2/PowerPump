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
    @State private var torchOn    = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                BarcodeCameraView(torchOn: torchOn) { code in handle(code) }
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

                    // Torch toggle — most barcodes live in dim aisles or on
                    // matte packaging where the camera struggles to lock focus.
                    Button {
                        torchOn.toggle()
                        HapticManager.light()
                    } label: {
                        Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(torchOn ? .sbAccent : .white)
                            .frame(width: 46, height: 46)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.top, 16)

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
    var torchOn: Bool = false
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeCameraController {
        let vc = BarcodeCameraController()
        vc.onScan = onScan
        return vc
    }

    func updateUIViewController(_ vc: BarcodeCameraController, context: Context) {
        vc.setTorch(on: torchOn)
    }
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

    private var captureDevice: AVCaptureDevice?

    private func configureSession() {
        // Prefer the wide / dual camera — its closer minimum focus distance
        // makes scanning small barcodes much more reliable than the default.
        let device: AVCaptureDevice? = {
            if let dual = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                return dual
            }
            if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                return wide
            }
            return AVCaptureDevice.default(for: .video)
        }()
        guard let device,
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.beginConfiguration()
        session.addInput(input)
        // High-resolution preset helps with thin barcodes on dim shelves.
        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        }

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        // Accept every retail barcode format Apple supports — not just EAN/UPC,
        // so QR-coded supplements or PDF417 labels also work.
        output.metadataObjectTypes = [
            .ean13, .ean8, .upce, .code128, .code39, .code93,
            .itf14, .interleaved2of5, .qr, .pdf417, .dataMatrix,
        ]

        session.commitConfiguration()

        configureFocus(on: device)
        captureDevice = device

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        // Tap-to-focus: helpful when a label sits to the side of the viewfinder.
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)

        startSession()
    }

    // Continuous autofocus + auto-exposure aimed at the center of the screen
    // (where the user is positioning the barcode).
    private func configureFocus(on device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near    // bias for close objects
            }
            if device.isSmoothAutoFocusSupported {
                device.isSmoothAutoFocusEnabled = true
            }
            // The viewfinder lives in the middle of the screen — point focus there.
            let center = CGPoint(x: 0.5, y: 0.5)
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = center
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = center
            }
            device.unlockForConfiguration()
        } catch {
            // Non-fatal: the camera will still work, just less responsive.
        }
    }

    func setTorch(on: Bool) {
        guard let device = captureDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if on {
                if device.isTorchModeSupported(.on) {
                    try? device.setTorchModeOn(level: 1.0)
                }
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {}
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let device = captureDevice,
              let preview = previewLayer else { return }
        let point = gesture.location(in: view)
        let devicePoint = preview.captureDevicePointConverted(fromLayerPoint: point)
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
        } catch {}
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
        // Always release the torch when the sheet closes, otherwise it stays on
        // and runs the battery down even after the camera stops.
        setTorch(on: false)
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
