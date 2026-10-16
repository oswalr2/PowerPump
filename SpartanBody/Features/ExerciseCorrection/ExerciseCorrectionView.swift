import SwiftUI
import AVFoundation
import Vision

struct ExerciseCorrectionView: View {
    let initialExercise: SupportedExercise

    @StateObject private var detector = PoseDetectionService()
    @State private var selectedExercise: SupportedExercise
    @State private var tracker: LiveFormTracker
    @State private var repCount = 0
    @State private var showExercisePicker = false
    @State private var feedback = LiveFormTracker.position
    @State private var startedAt = Date()
    @State private var lastAnalysis = Date.distantPast
    @Environment(\.dismiss) private var dismiss

    init(exercise: SupportedExercise = .squat) {
        initialExercise = exercise
        _selectedExercise = State(initialValue: exercise)
        _tracker = State(initialValue: LiveFormTracker(exercise: exercise.videoExercise))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Camera preview
            CameraPreviewView(session: detector.session)
                .ignoresSafeArea()

            // Skeleton overlay
            if detector.isPersonDetected {
                SkeletonOverlayView(joints: detector.joints, badJoints: feedback.badJoints, aspect: detector.aspect)
                    .ignoresSafeArea()
            }

            // UI overlay
            if detector.permissionDenied {
                cameraDeniedView
            } else {
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    bottomPanel
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .onAppear {
            detector.setup(front: false)
            detector.start()
        }
        .onDisappear { detector.stop() }
        .onChange(of: detector.joints) { newJoints in
            updateAnalysis(newJoints)
        }
        .sheet(isPresented: $showExercisePicker) {
            ExerciseSelectorSheet(selected: $selectedExercise, onSelect: {
                tracker = LiveFormTracker(exercise: selectedExercise.videoExercise)
                startedAt = Date()
                repCount = 0
                feedback = LiveFormTracker.position
                showExercisePicker = false
            })
        }
    }

    // MARK: - Camera denied

    private var cameraDeniedView: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "video.slash.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white.opacity(0.8))
                Text("Camera access is off")
                    .font(SBFont.heading(17))
                    .foregroundColor(.white)
                Text("Enable camera access for PowerPump in iOS Settings to check your form live.")
                    .font(SBFont.caption())
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(SBFont.body())
                        .fontWeight(.semibold)
                        .foregroundColor(.sbAccent)
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            // Exercise selector pill
            Button { showExercisePicker = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedExercise.icon)
                        .font(.system(size: 13, weight: .semibold))
                    Text(LocalizedStringKey(selectedExercise.nameKey))
                        .font(SBFont.caption())
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }

            Spacer()

            // Rep counter
            VStack(spacing: 1) {
                Text("\(repCount)")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                Text(EXL("Reps").lowercased())
                    .font(SBFont.label(10))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 38)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    // MARK: - Bottom panel

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            // Hint pill
            if !detector.isPersonDetected {
                Text(LocalizedStringKey(selectedExercise.cameraKey))
                    .font(SBFont.caption())
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
                    .padding(.bottom, 12)
            }

            // Feedback card
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(feedback.isGood ? Color.sbGreen : Color.sbRed)
                        .frame(width: 44, height: 44)
                    Image(systemName: feedback.isGood ? "checkmark" : "exclamationmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(feedback.titleKey))
                        .font(SBFont.heading(16))
                        .foregroundColor(.white)
                    if !feedback.detail.isEmpty {
                        Text(verbatim: feedback.detail)
                            .font(SBFont.caption())
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .padding(18)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: feedback.titleKey)
    }

    // MARK: - Logic

    private func updateAnalysis(_ joints: [BodyJoint: CGPoint]) {
        // Aspect-corrected, like the video analysis: angles measured on the
        // raw portrait coordinates came out squashed.
        let points = joints.mapValues { CGPoint(x: $0.x * detector.aspect, y: $0.y) }
        guard tracker.add(points, at: Date().timeIntervalSince(startedAt)) else { return }
        // A few reviews a second are plenty and keep the phone cool.
        guard Date().timeIntervalSince(lastAnalysis) > 0.3 else { return }
        lastAnalysis = Date()
        feedback = tracker.analyze()
        if tracker.reps > repCount {
            repCount = tracker.reps
            feedback.isGood ? HapticManager.success() : HapticManager.warning()
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - Skeleton Overlay

struct SkeletonOverlayView: View {
    let joints: [BodyJoint: CGPoint]
    let badJoints: Set<BodyJoint>
    /// Width / height of the camera frames.
    let aspect: CGFloat

    private let connections: [(BodyJoint, BodyJoint)] = [
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]

    var body: some View {
        Canvas { ctx, size in
            for (a, b) in connections {
                guard let pa = joints[a], let pb = joints[b] else { continue }
                var path = Path()
                path.move(to: visionToScreen(pa, size: size))
                path.addLine(to: visionToScreen(pb, size: size))
                let isBad = badJoints.contains(a) || badJoints.contains(b)
                ctx.stroke(path, with: .color(isBad ? .red.opacity(0.85) : .green.opacity(0.8)), lineWidth: 3)
            }
            for (name, point) in joints {
                let pt = visionToScreen(point, size: size)
                let isBad = badJoints.contains(name)
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 5, y: pt.y - 5, width: 10, height: 10)),
                         with: .color(isBad ? .red : .green))
            }
        }
        .allowsHitTesting(false)
    }

    /// The preview fills the screen and crops the frame's overflow, so the
    /// skeleton has to be placed on the same scaled, centred frame — mapped
    /// straight onto the screen it drifted sideways from the body.
    private func visionToScreen(_ pt: CGPoint, size: CGSize) -> CGPoint {
        let frameH = max(size.height, size.width / aspect)
        let frameW = frameH * aspect
        return CGPoint(x: pt.x * frameW - (frameW - size.width) / 2,
                       y: (1 - pt.y) * frameH - (frameH - size.height) / 2)
    }
}

// MARK: - Exercise Selector Sheet

private struct ExerciseSelectorSheet: View {
    @Binding var selected: SupportedExercise
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                List(SupportedExercise.allCases) { exercise in
                    Button {
                        selected = exercise
                        onSelect()
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.sbSurfaceRaised)
                                    .frame(width: 40, height: 40)
                                Image(systemName: exercise.icon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.sbAccent)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey(exercise.nameKey))
                                    .font(SBFont.body())
                                    .foregroundColor(.sbTextPrimary)
                                Text(LocalizedStringKey(exercise.cameraKey))
                                    .font(SBFont.caption())
                                    .foregroundColor(.sbTextSecondary)
                            }
                            Spacer()
                            if selected == exercise {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.sbAccent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.sbSurface)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.sbAccent)
                }
            }
        }
    }
}
