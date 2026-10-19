import Foundation
import CoreGraphics

var failures = 0
func check(_ ok: Bool, _ what: String) {
    print(ok ? "  PASS  " : "  FAIL  ", what); if !ok { failures += 1 }
}

// ── Synthetic side-view skeletons ────────────────────────────────────────
func rot(_ v: CGPoint, _ deg: Double) -> CGPoint {
    let r = deg * .pi / 180
    return CGPoint(x: v.x * cos(r) - v.y * sin(r), y: v.x * sin(r) + v.y * cos(r))
}
func add(_ a: CGPoint, _ b: CGPoint, _ k: CGFloat = 1) -> CGPoint { CGPoint(x: a.x + b.x * k, y: a.y + b.y * k) }
/// Deterministic generator (SplitMix64) so a failing run can be reproduced:
/// the same seed always produces the same synthetic skeletons.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
var rng = SplitMix64(seed: 42)
func jitter(_ p: CGPoint, _ n: CGFloat) -> CGPoint {
    CGPoint(x: p.x + .random(in: -n...n, using: &rng), y: p.y + .random(in: -n...n, using: &rng))
}
/// Jitters every joint in a fixed order (dictionary iteration order changes
/// between runs, which would otherwise make the seeded noise non-repeatable).
func jittered(_ pts: [BodyJoint: CGPoint], _ n: CGFloat) -> [BodyJoint: CGPoint] {
    var out = pts
    for j in BodyJoint.allCases { if let p = pts[j] { out[j] = jitter(p, n) } }
    return out
}

/// Standing/squatting body facing +x. knee = hip–knee–ankle angle, lean =
/// torso from vertical, elbow = arm angle, hipsFirst lets the hip fold while
/// the knee is straight.
func standing(knee: Double, lean: Double, elbow: Double = 170, shinTilt: Double = 15,
              side: String = "left", noise: CGFloat = 0.004, frontal: Bool = false) -> [BodyJoint: CGPoint] {
    let ankle = CGPoint(x: 0.5, y: 0.1)
    let shinDir = rot(CGPoint(x: 0, y: 1), -shinTilt)            // tilts forward (+x)
    let kneeP = add(ankle, shinDir, 0.22)
    let down = CGPoint(x: -shinDir.x, y: -shinDir.y)             // knee → ankle
    let thighDir = rot(down, -knee)                               // hip goes back (−x)
    let hipP = add(kneeP, thighDir, 0.22)
    let torsoDir = rot(CGPoint(x: 0, y: 1), -lean)
    let shoulder = add(hipP, torsoDir, 0.26)
    let upper = rot(CGPoint(x: 0, y: -1), -20)
    let elbowP = add(shoulder, upper, 0.13)
    let fore = rot(CGPoint(x: -upper.x, y: -upper.y), elbow)
    let wrist = add(elbowP, fore, 0.12)
    let nose = add(shoulder, torsoDir, 0.1)
    var pts: [BodyJoint: CGPoint] = [:]
    let (s, e, w, h, k, a) = side == "left"
        ? (BodyJoint.leftShoulder, BodyJoint.leftElbow, BodyJoint.leftWrist, BodyJoint.leftHip, BodyJoint.leftKnee, BodyJoint.leftAnkle)
        : (.rightShoulder, .rightElbow, .rightWrist, .rightHip, .rightKnee, .rightAnkle)
    pts[s] = shoulder; pts[e] = elbowP; pts[w] = wrist; pts[h] = hipP; pts[k] = kneeP; pts[a] = ankle
    pts[.nose] = nose
    if frontal {   // other shoulder far away: camera sees the chest
        pts[side == "left" ? .rightShoulder : .leftShoulder] = CGPoint(x: shoulder.x + 0.2, y: shoulder.y)
    } else {       // other shoulder nearly behind
        pts[side == "left" ? .rightShoulder : .leftShoulder] = CGPoint(x: shoulder.x + 0.02, y: shoulder.y)
    }
    return jittered(pts, noise)
}

/// Horizontal body for push-ups / plank. offset: hip above (+) / below (−) line.
func prone(elbow: Double, offset: CGFloat, noise: CGFloat = 0.004) -> [BodyJoint: CGPoint] {
    let wrist = CGPoint(x: 0.8, y: 0.1)
    let d = sqrt(0.13 * 0.13 + 0.13 * 0.13 - 2 * 0.13 * 0.13 * cos(elbow * .pi / 180))
    let shoulder = CGPoint(x: 0.8, y: 0.1 + CGFloat(d))
    let elbowP = CGPoint(x: 0.8 - CGFloat(0.13 * sin((180 - elbow) / 2 * .pi / 180)), y: 0.1 + CGFloat(d) / 2)
    let ankle = CGPoint(x: 0.15, y: 0.1)
    let mid = CGPoint(x: (shoulder.x + ankle.x) / 2, y: (shoulder.y + ankle.y) / 2 + offset * 0.3)
    let pts: [BodyJoint: CGPoint] = [.leftShoulder: shoulder, .leftElbow: elbowP, .leftWrist: wrist,
                                     .leftHip: mid, .leftKnee: CGPoint(x: 0.33, y: 0.1 + (mid.y - 0.1) / 2),
                                     .leftAnkle: ankle, .nose: CGPoint(x: 0.88, y: shoulder.y + 0.03)]
    return jittered(pts, noise)
}

/// Frames at 12 fps following `curve(t)` → joints.
func video(seconds: Double, _ make: (Double) -> [BodyJoint: CGPoint]) -> [PoseFrame] {
    stride(from: 0.0, to: seconds, by: 1.0 / 12).map { PoseFrame(time: $0, points: make($0)) }
}
/// 0 → 1 → 0 once per `period` seconds, starting at 0.
func wave(_ t: Double, period: Double) -> Double { (1 - cos(2 * .pi * t / period)) / 2 }

func run(_ name: String, _ frames: [PoseFrame], _ ex: VideoExercise) -> FormReport? {
    switch VideoFormEngine.analyze(frames, exercise: ex) {
    case .success(let r):
        print("     \(name): \(r.reps.count) reps · nota \(r.score) · issues \(r.issues.map(\.rule)) · lado \(r.side)"
              + (r.holdSeconds.map { String(format: " · %.1f s", $0) } ?? "")
              + (r.warnings.isEmpty ? "" : " · avisos \(r.warnings)") + (r.fatigue ? " · fatiga" : ""))
        return r
    case .failure(let e):
        print("     \(name): error \(e)"); return nil
    }
}


print("Tracker en vivo")
// Sentadilla: 5 reps buenas a 30 fps (la cámara real va más rápido que el motor).
var t = LiveFormTracker(exercise: .squat)
var counts: [Int] = []
var sawEarlyWarning = false
for i in 0..<Int(12.5 * 30) {
    let time = Double(i) / 30
    let d = wave(time, period: 2.5)
    if t.add(standing(knee: 172 - 92 * d, lean: 10 + 28 * d), at: time) {
        let f = t.analyze()
        counts.append(t.reps)
        if f.state == .fix { sawEarlyWarning = true }
    }
}
check(t.reps == 5, "cuenta las 5 reps en vivo (\(t.reps))")
check(!sawEarlyWarning, "no avisa de errores falsos en medio de reps buenas")
check(counts == counts.sorted(), "el contador nunca baja")
// Cuenta la rep cuando termina, no al bajar
var t2 = LiveFormTracker(exercise: .squat)
var countAtBottom = -1
for i in 0..<Int(2.5 * 30) {
    let time = Double(i) / 30
    if t2.add(standing(knee: 172 - 92 * wave(time, period: 2.5), lean: 10), at: time) { _ = t2.analyze() }
    if abs(time - 1.25) < 0.02 { countAtBottom = t2.reps }
}
_ = t2.add(standing(knee: 172, lean: 10), at: 2.6); _ = t2.add(standing(knee: 172, lean: 10), at: 2.7); _ = t2.analyze()
check(countAtBottom == 0, "no cuenta la rep mientras estás abajo (\(countAtBottom))")
check(t2.reps == 1, "la cuenta al volver arriba (\(t2.reps))")

// Sentadilla corta: debe avisar de profundidad
var t3 = LiveFormTracker(exercise: .squat)
var last = LiveFormTracker.position
for i in 0..<Int(7.5 * 30) {
    let time = Double(i) / 30
    if t3.add(standing(knee: 172 - 62 * wave(time, period: 2.5), lean: 12), at: time) { last = t3.analyze() }
}
check(last.titleKey == "form.rule.squat.depth.title", "avisa de poca profundidad (\(last.titleKey))")
check(last.badJoints.contains(.leftKnee), "marca las rodillas en rojo")

// Curl de pie: el antiguo contador nunca contaba curls
var t4 = LiveFormTracker(exercise: .bicepCurl)
for i in 0..<Int(10 * 30) {
    let time = Double(i) / 30
    if t4.add(standing(knee: 175, lean: 5, elbow: 170 - 125 * wave(time, period: 2.5)), at: time) { _ = t4.analyze() }
}
check(t4.reps >= 3, "cuenta curls (\(t4.reps))")

// Sin persona
var t5 = LiveFormTracker(exercise: .squat)
t5.add([:], at: 0)
check(t5.analyze().state == .position, "sin cuerpo pide colocarse")

// Plancha: muestra segundos aguantados
var t6 = LiveFormTracker(exercise: .plank)
var pf = LiveFormTracker.position
for i in 0..<(12 * 30) { let time = Double(i) / 30; if t6.add(prone(elbow: 170, offset: 0), at: time) { pf = t6.analyze() } }
check(pf.state == .hold, "plancha: estado aguantando (\(pf.state))")

// Serie larga: el búfer se recorta sin perder la cuenta
var t7 = LiveFormTracker(exercise: .squat)
for i in 0..<Int(150 * 12) {
    let time = Double(i) / 12
    if t7.add(standing(knee: 172 - 92 * wave(time, period: 2.5), lean: 10 + 28 * wave(time, period: 2.5)), at: time), i % 6 == 0 { _ = t7.analyze() }
}
_ = t7.analyze()
check(abs(t7.reps - 60) <= 1, "serie de 150 s: \(t7.reps) reps de 60, búfer \(t7.frames.count) frames")
print(failures == 0 ? "TODO OK" : "\(failures) FALLOS")
exit(failures == 0 ? 0 : 1)
