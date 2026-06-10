import Vision
import CoreGraphics

struct FormFeedback {
    let message: String
    let detail: String
    let isGood: Bool
    let badJoints: Set<VNHumanBodyPoseObservation.JointName>
}

enum SupportedExercise: String, CaseIterable, Identifiable {
    case squat          = "squat"
    case pushUp         = "push_up"
    case deadlift       = "deadlift"
    case overheadPress  = "overhead_press"
    case plank          = "plank"
    case bicepCurl      = "barbell_curl"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .squat:         return "Squat"
        case .pushUp:        return "Push-up"
        case .deadlift:      return "Deadlift"
        case .overheadPress: return "Overhead Press"
        case .plank:         return "Plank"
        case .bicepCurl:     return "Bicep Curl"
        }
    }

    var icon: String {
        switch self {
        case .squat:         return "figure.strengthtraining.traditional"
        case .pushUp:        return "figure.core.training"
        case .deadlift:      return "figure.strengthtraining.traditional"
        case .overheadPress: return "figure.arms.open"
        case .plank:         return "figure.core.training"
        case .bicepCurl:     return "figure.strengthtraining.traditional"
        }
    }

    var cameraHint: String {
        switch self {
        case .squat, .deadlift: return "Stand sideways to the camera"
        case .pushUp, .plank:   return "Set phone on the floor facing you"
        case .overheadPress:    return "Face the camera or stand sideways"
        case .bicepCurl:        return "Stand sideways to the camera"
        }
    }

    // Which joint to track for rep counting (normalized y)
    var repTrackingJoint: VNHumanBodyPoseObservation.JointName {
        switch self {
        case .squat, .deadlift: return .leftHip
        case .pushUp, .plank:   return .leftShoulder
        case .overheadPress:    return .leftWrist
        case .bicepCurl:        return .leftWrist
        }
    }
}

struct ExerciseFormAnalyzer {

    static func analyze(
        exercise: SupportedExercise,
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> FormFeedback {
        switch exercise {
        case .squat:         return analyzeSquat(joints)
        case .pushUp:        return analyzePushUp(joints)
        case .deadlift:      return analyzeDeadlift(joints)
        case .overheadPress: return analyzeOHP(joints)
        case .plank:         return analyzePlank(joints)
        case .bicepCurl:     return analyzeCurl(joints)
        }
    }

    // MARK: - Squat

    private static func analyzeSquat(_ j: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> FormFeedback {
        guard let hip   = point(j, .leftHip),
              let knee  = point(j, .leftKnee),
              let ankle = point(j, .leftAnkle),
              let shoulder = point(j, .leftShoulder) else {
            return notDetected()
        }

        let kneeAngle  = angle(hip, knee, ankle)
        let torsoAngle = verticalAngle(shoulder, hip)

        // Standing (not in squat position)
        if kneeAngle > 155 {
            return FormFeedback(
                message: "Ready", detail: "Start your squat — go down",
                isGood: true, badJoints: []
            )
        }

        var issues: [String] = []
        var bad: Set<VNHumanBodyPoseObservation.JointName> = []

        // Depth check
        if kneeAngle > 110 {
            issues.append("Go lower")
            bad.insert(.leftKnee)
        }

        // Torso uprightness (>45° forward lean is bad)
        if torsoAngle > 45 {
            issues.append("Chest up, lean back less")
            bad.insert(.leftShoulder)
        }

        if issues.isEmpty {
            return FormFeedback(message: "Great squat!", detail: "Good depth and posture", isGood: true, badJoints: [])
        }
        return FormFeedback(message: issues[0], detail: issues.dropFirst().joined(separator: " · "), isGood: false, badJoints: bad)
    }

    // MARK: - Push-up

    private static func analyzePushUp(_ j: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> FormFeedback {
        guard let shoulder = point(j, .leftShoulder),
              let elbow    = point(j, .leftElbow),
              let wrist    = point(j, .leftWrist),
              let hip      = point(j, .leftHip),
              let ankle    = point(j, .leftAnkle) else {
            return notDetected()
        }

        let elbowAngle = angle(shoulder, elbow, wrist)
        let bodyAngle  = angle(shoulder, hip, ankle)

        var issues: [String] = []
        var bad: Set<VNHumanBodyPoseObservation.JointName> = []

        // At the bottom: elbow should be ~90°
        if elbowAngle < 150 && elbowAngle > 115 {
            issues.append("Lower your chest more")
            bad.insert(.leftElbow)
        }

        // Body alignment: hips shouldn't sag or pike (should be ~170-180°)
        if bodyAngle < 155 {
            issues.append("Keep hips level — straight body")
            bad.insert(.leftHip)
        } else if bodyAngle > 195 {
            issues.append("Lower your hips — no piking")
            bad.insert(.leftHip)
        }

        if issues.isEmpty {
            return FormFeedback(message: "Perfect form!", detail: "Straight body, full range", isGood: true, badJoints: [])
        }
        return FormFeedback(message: issues[0], detail: issues.dropFirst().joined(separator: " · "), isGood: false, badJoints: bad)
    }

    // MARK: - Deadlift

    private static func analyzeDeadlift(_ j: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> FormFeedback {
        guard let shoulder = point(j, .leftShoulder),
              let hip      = point(j, .leftHip),
              let knee     = point(j, .leftKnee) else {
            return notDetected()
        }

        let torsoAngle = verticalAngle(shoulder, hip)
        let hipKneeAngle = angle(shoulder, hip, knee)

        var issues: [String] = []
        var bad: Set<VNHumanBodyPoseObservation.JointName> = []

        // At setup/mid-pull, back angle > 60° = rounded back
        if torsoAngle > 60 {
            issues.append("Keep back straight — neutral spine")
            bad.insert(.leftShoulder)
            bad.insert(.leftHip)
        }

        // Check hip hinge (hip should be lower than shoulders)
        if hipKneeAngle < 80 {
            issues.append("Push hips back more")
            bad.insert(.leftHip)
        }

        if issues.isEmpty {
            return FormFeedback(message: "Solid pull!", detail: "Good back angle and hinge", isGood: true, badJoints: [])
        }
        return FormFeedback(message: issues[0], detail: issues.dropFirst().joined(separator: " · "), isGood: false, badJoints: bad)
    }

    // MARK: - Overhead Press

    private static func analyzeOHP(_ j: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> FormFeedback {
        guard let shoulder = point(j, .leftShoulder),
              let elbow    = point(j, .leftElbow),
              let wrist    = point(j, .leftWrist),
              let hip      = point(j, .leftHip) else {
            return notDetected()
        }

        let elbowAngle  = angle(shoulder, elbow, wrist)
        let torsoAngle  = verticalAngle(shoulder, hip)

        var issues: [String] = []
        var bad: Set<VNHumanBodyPoseObservation.JointName> = []

        // Arms not fully extended at top
        if elbowAngle < 155 {
            issues.append("Fully extend arms overhead")
            bad.insert(.leftElbow)
        }

        // Excessive back arch
        if torsoAngle > 20 {
            issues.append("Brace core — don't arch back")
            bad.insert(.leftHip)
        }

        if issues.isEmpty {
            return FormFeedback(message: "Strong press!", detail: "Arms locked out, core braced", isGood: true, badJoints: [])
        }
        return FormFeedback(message: issues[0], detail: issues.dropFirst().joined(separator: " · "), isGood: false, badJoints: bad)
    }

    // MARK: - Plank

    private static func analyzePlank(_ j: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> FormFeedback {
        guard let shoulder = point(j, .leftShoulder),
              let hip      = point(j, .leftHip),
              let ankle    = point(j, .leftAnkle) else {
            return notDetected()
        }

        let bodyAngle = angle(shoulder, hip, ankle)

        if bodyAngle < 160 {
            return FormFeedback(
                message: "Raise your hips", detail: "Keep body in a straight line",
                isGood: false, badJoints: [.leftHip]
            )
        }
        if bodyAngle > 195 {
            return FormFeedback(
                message: "Lower your hips", detail: "Don't let hips pike up",
                isGood: false, badJoints: [.leftHip]
            )
        }
        return FormFeedback(message: "Hold it!", detail: "Perfect plank position", isGood: true, badJoints: [])
    }

    // MARK: - Bicep Curl

    private static func analyzeCurl(_ j: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> FormFeedback {
        guard let shoulder = point(j, .leftShoulder),
              let elbow    = point(j, .leftElbow),
              let wrist    = point(j, .leftWrist) else {
            return notDetected()
        }

        let elbowAngle = angle(shoulder, elbow, wrist)
        let elbowX     = elbow.location.x
        let shoulderX  = shoulder.location.x

        var issues: [String] = []
        var bad: Set<VNHumanBodyPoseObservation.JointName> = []

        // Elbow flaring out (should stay at side)
        if abs(elbowX - shoulderX) > 0.15 {
            issues.append("Keep elbow at your side")
            bad.insert(.leftElbow)
        }

        // Full ROM: should reach ~40° at top and ~160° at bottom
        if elbowAngle > 155 && elbowAngle < 170 {
            issues.append("Curl all the way up")
            bad.insert(.leftElbow)
        }

        if issues.isEmpty {
            return FormFeedback(message: "Good curl!", detail: "Full range, elbow fixed", isGood: true, badJoints: [])
        }
        return FormFeedback(message: issues[0], detail: issues.dropFirst().joined(separator: " · "), isGood: false, badJoints: bad)
    }

    // MARK: - Geometry helpers

    private static func notDetected() -> FormFeedback {
        FormFeedback(message: "Position yourself in frame", detail: "Make sure your full body is visible", isGood: false, badJoints: [])
    }

    private static func point(_ j: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
                               _ name: VNHumanBodyPoseObservation.JointName) -> VNRecognizedPoint? {
        guard let p = j[name], p.confidence > 0.3 else { return nil }
        return p
    }

    static func angle(_ a: VNRecognizedPoint, _ b: VNRecognizedPoint, _ c: VNRecognizedPoint) -> Double {
        angle(a.location, b.location, c.location)
    }

    static func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let ba = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let bc = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = ba.dx * bc.dx + ba.dy * bc.dy
        let mag = sqrt(ba.dx*ba.dx + ba.dy*ba.dy) * sqrt(bc.dx*bc.dx + bc.dy*bc.dy)
        guard mag > 0 else { return 0 }
        return acos(Double(max(-1.0, min(1.0, dot / mag)))) * 180.0 / .pi
    }

    // Angle of a segment from vertical (0° = straight up)
    private static func verticalAngle(_ top: VNRecognizedPoint, _ bottom: VNRecognizedPoint) -> Double {
        let dx = top.location.x - bottom.location.x
        let dy = top.location.y - bottom.location.y
        return abs(atan2(dx, dy) * 180 / .pi)
    }
}
