import AVFoundation
import Vision
import UIKit

final class PoseDetectionService: NSObject, ObservableObject {

    @Published var joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint] = [:]
    @Published var isPersonDetected = false

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "sb.pose.processing", qos: .userInteractive)
    private var useFrontCamera = true

    // MARK: - Setup

    func setup(front: Bool = true) {
        useFrontCamera = front
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: front ? .front : .back
        ), let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) { session.addInput(input) }

        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        // Fix orientation for portrait
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            if front { connection.isVideoMirrored = true }
        }

        session.commitConfiguration()
    }

    func start() {
        guard !session.isRunning else { return }
        processingQueue.async { self.session.startRunning() }
    }

    func stop() {
        guard session.isRunning else { return }
        processingQueue.async { self.session.stopRunning() }
    }
}

// MARK: - Sample Buffer Delegate

extension PoseDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer,
                                            orientation: .up,
                                            options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first as? VNHumanBodyPoseObservation else {
                DispatchQueue.main.async { self.isPersonDetected = false; self.joints = [:] }
                return
            }
            let allJoints = (try? observation.recognizedPoints(.all)) ?? [:]
            DispatchQueue.main.async {
                self.isPersonDetected = true
                self.joints = allJoints
            }
        } catch {
            DispatchQueue.main.async { self.isPersonDetected = false; self.joints = [:] }
        }
    }
}
