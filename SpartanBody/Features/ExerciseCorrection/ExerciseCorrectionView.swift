import SwiftUI
import AVFoundation
import Vision

struct ExerciseCorrectionView: View {
    let initialExercise: SupportedExercise

    @StateObject private var detector = PoseDetectionService()
    @State private var selectedExercise: SupportedExercise
    @State private var repCount = 0
    @State private var repPhase: RepPhase = .unknown
    @State private var repBaseline: Double = 0
    @State private var showExercisePicker = false
    @State private var feedback = FormFeedback(message: "Position yourself in frame",
                                               detail: "Make sure your full body is visible",
                                               isGood: false, badJoints: [])
    @Environment(\.dismiss) private var dismiss

    init(exercise: SupportedExercise = .squat) {
        initialExercise = exercise
        _selectedExercise = State(initialValue: exercise)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Camera preview
            CameraPreviewView(session: detector.session)
                .ignoresSafeArea()

            // Skeleton overlay
            if detector.isPersonDetected {
                SkeletonOverlayView(joints: detector.joints, badJoints: feedback.badJoints)
                    .ignoresSafeArea()
            }

            // UI overlay
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomPanel
            }
            .ignoresSafeArea(edges: .top)
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
                repCount = 0
                repPhase = .unknown
                showExercisePicker = false
            })
        }
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
                    Text(selectedExercise.displayName)
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
                Text("reps")
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
                Text(selectedExercise.cameraHint)
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
                    Text(feedback.message)
                        .font(SBFont.heading(16))
                        .foregroundColor(.white)
                    if !feedback.detail.isEmpty {
                        Text(feedback.detail)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: feedback.message)
    }

    // MARK: - Logic

    private func updateAnalysis(_ joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        guard !joints.isEmpty else { return }

        // Form analysis
        feedback = ExerciseFormAnalyzer.analyze(exercise: selectedExercise, joints: joints)

        // Rep counting
        let trackJoint = selectedExercise.repTrackingJoint
        guard let joint = joints[trackJoint], joint.confidence > 0.4 else { return }
        let y = joint.location.y  // Vision: 0 = bottom, 1 = top

        switch repPhase {
        case .unknown:
            repBaseline = y
            repPhase = .up

        case .up:
            // Went down significantly
            if y < repBaseline * 0.78 {
                repPhase = .down
            }

        case .down:
            // Came back up
            if y > repBaseline * 0.88 {
                repPhase = .up
                repCount += 1
                HapticManager.medium()
            }
        }
    }
}

// MARK: - Rep phase

private enum RepPhase { case unknown, up, down }

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
    let joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    let badJoints: Set<VNHumanBodyPoseObservation.JointName>

    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                // Draw connections
                for (a, b) in connections {
                    guard let pa = joints[a], let pb = joints[b],
                          pa.confidence > 0.3, pb.confidence > 0.3 else { continue }
                    let ptA = visionToScreen(pa.location, size: size)
                    let ptB = visionToScreen(pb.location, size: size)
                    var path = Path()
                    path.move(to: ptA)
                    path.addLine(to: ptB)
                    let isBad = badJoints.contains(a) || badJoints.contains(b)
                    ctx.stroke(path, with: .color(isBad ? .red.opacity(0.85) : .green.opacity(0.8)), lineWidth: 3)
                }

                // Draw joint dots
                for (name, point) in joints where point.confidence > 0.3 {
                    let pt = visionToScreen(point.location, size: size)
                    let rect = CGRect(x: pt.x - 5, y: pt.y - 5, width: 10, height: 10)
                    let isBad = badJoints.contains(name)
                    ctx.fill(Path(ellipseIn: rect), with: .color(isBad ? .red : .green))
                }
            }
        }
    }

    private func visionToScreen(_ pt: CGPoint, size: CGSize) -> CGPoint {
        // Vision: origin bottom-left, y up → SwiftUI: origin top-left, y down
        CGPoint(x: pt.x * size.width, y: (1 - pt.y) * size.height)
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
                                Text(exercise.displayName)
                                    .font(SBFont.body())
                                    .foregroundColor(.sbTextPrimary)
                                Text(exercise.cameraHint)
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
