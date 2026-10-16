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

// ── Tests ────────────────────────────────────────────────────────────────
print("Sentadilla")
let goodSquat = run("buena", video(seconds: 12.5) { t in
    let d = wave(t, period: 2.5); return standing(knee: 172 - 92 * d, lean: 10 + 28 * d) }, .squat)
check(goodSquat?.reps.count == 5, "5 reps contadas")
check(goodSquat?.issues.isEmpty == true, "sin errores en una sentadilla profunda")

let shallow = run("corta", video(seconds: 10) { t in
    let d = wave(t, period: 2.5); return standing(knee: 172 - 62 * d, lean: 10 + 25 * d) }, .squat)
check(shallow?.issues.first?.rule == "squat.depth", "detecta falta de profundidad")

let chest = run("pecho cae", video(seconds: 10) { t in
    let d = wave(t, period: 2.5); return standing(knee: 172 - 92 * d, lean: 10 + 55 * d) }, .squat)
check(chest?.issues.contains { $0.rule == "squat.chest" } == true, "detecta pecho hacia delante")

let right = run("grabada desde la derecha", video(seconds: 10) { t in
    let d = wave(t, period: 2.5); return standing(knee: 172 - 92 * d, lean: 10 + 28 * d, side: "right") }, .squat)
check(right?.side == "right" && right?.reps.count == 4, "usa el lado derecho si es el visible")

let front = run("de frente", video(seconds: 10) { t in
    let d = wave(t, period: 2.5); return standing(knee: 172 - 92 * d, lean: 10 + 28 * d, frontal: true) }, .squat)
check(front?.warnings.contains("form.warn.front") == true, "avisa si se grabó de frente")

let noisy = run("con temblor", video(seconds: 10) { t in
    let d = wave(t, period: 2.5); return standing(knee: 172 - 92 * d, lean: 10 + 28 * d, noise: 0.012) }, .squat)
check(noisy?.reps.count == 4, "el temblor de la cámara no inventa reps (\(noisy?.reps.count ?? -1))")

let tired = run("se cansa", video(seconds: 15) { t in
    let d = wave(t, period: 2.5); let k = t < 7.5 ? 92.0 : 58.0
    return standing(knee: 172 - k * d, lean: 10 + 28 * d) }, .squat)
check(tired?.fatigue == true, "detecta que la técnica cae al final")
check(tired?.worstRep.map { $0.number >= 4 } == true, "la peor rep está al final")

print("Nada que analizar")
switch VideoFormEngine.analyze(video(seconds: 5) { _ in [:] }, exercise: .squat) {
case .failure(let e): check(e == .bodyNotVisible, "sin cuerpo → error claro")
default: check(false, "sin cuerpo → error claro")
}
switch VideoFormEngine.analyze(video(seconds: 6) { _ in standing(knee: 172, lean: 5) }, exercise: .squat) {
case .failure(let e): check(e == .noReps, "quieto → 'no hay repeticiones'")
default: check(false, "quieto → 'no hay repeticiones'")
}

print("Peso muerto")
let dl = run("caderas primero", video(seconds: 10) { t in
    let d = 1 - wave(t, period: 2.5)                     // starts at the floor
    let hip = 172 - 95 * d
    // Knees lock out long before the hips open.
    let kneeAngle = d > 0.35 ? 120 + (1 - d) * 90 : 178
    return standing(knee: kneeAngle, lean: 10 + 70 * d, shinTilt: 5).merging(
        [:], uniquingKeysWith: { a, _ in a }).mapValues { $0 } |> { pts in
            // Recompute shoulder so shoulder–hip–knee matches `hip`.
            var p = pts
            if let h = p[.leftHip], let k = p[.leftKnee] {
                let down = CGPoint(x: k.x - h.x, y: k.y - h.y)
                let n = hypot(down.x, down.y)
                p[.leftShoulder] = add(h, rot(CGPoint(x: down.x / n, y: down.y / n), -hip), 0.26)
            }
            return p } }, .deadlift)
check(dl?.issues.contains { $0.rule == "deadlift.hipsFirst" } == true, "detecta caderas que suben primero")

print("Flexiones")
let pushGood = run("buenas", video(seconds: 10) { t in
    prone(elbow: 170 - 88 * wave(t, period: 2), offset: 0) }, .pushUp)
check(pushGood?.reps.count == 5 && pushGood?.issues.isEmpty == true, "5 flexiones limpias")
let pushSag = run("cadera caída", video(seconds: 10) { t in
    prone(elbow: 170 - 88 * wave(t, period: 2), offset: -0.45) }, .pushUp)
check(pushSag?.issues.contains { $0.rule == "pushup.sag" } == true, "detecta cadera caída")
let pushShort = run("poco recorrido", video(seconds: 10) { t in
    prone(elbow: 170 - 55 * wave(t, period: 2), offset: 0) }, .pushUp)
check(pushShort?.issues.first?.rule == "pushup.depth", "detecta flexiones cortas")

print("Plancha")
let plank = run("se hunde", video(seconds: 12) { t in prone(elbow: 90, offset: t > 5 ? -0.5 : 0) }, .plank)
check(plank?.issues.first?.rule == "plank.sag", "detecta que la cadera cae al aguantar")
check((plank?.holdSeconds ?? 0) > 11, "mide el tiempo aguantado")


print("Curl")
let curlSwing = run("con balanceo", video(seconds: 10) { t in
    let d = wave(t, period: 2.5); return standing(knee: 175, lean: 3 + 22 * d, elbow: 170 - 125 * d) }, .bicepCurl)
check(curlSwing?.issues.contains { $0.rule == "curl.swing" } == true, "detecta balanceo del cuerpo")
let curlGood = run("limpio", video(seconds: 10) { t in
    let d = wave(t, period: 2.5); return standing(knee: 175, lean: 4, elbow: 170 - 125 * d) }, .bicepCurl)
check(curlGood?.reps.count == 4 && curlGood?.issues.isEmpty == true, "curl limpio sin errores")

print("Robustez: 13 ejercicios × vídeos raros")
var crashes = 0, results = 0
let weird: [(String, [PoseFrame])] = [
    ("aleatorio", video(seconds: 8) { _ in Dictionary(uniqueKeysWithValues: BodyJoint.allCases.map {
        ($0, CGPoint(x: .random(in: 0...0.6, using: &rng), y: .random(in: 0...1, using: &rng))) }) }),
    ("entra y sale", video(seconds: 10) { t in Int(t) % 2 == 0 ? standing(knee: 172 - 92 * wave(t, period: 2.5), lean: 20) : [:] }),
    ("1 segundo", video(seconds: 1) { t in standing(knee: 150, lean: 10) }),
    ("medio cuerpo", video(seconds: 8) { t in standing(knee: 172 - 92 * wave(t, period: 2.5), lean: 20)
        .filter { [.leftShoulder, .leftElbow, .leftWrist, .nose].contains($0.key) } }),
    ("puntos repetidos", video(seconds: 6) { _ in Dictionary(uniqueKeysWithValues: BodyJoint.allCases.map { ($0, CGPoint(x: 0.3, y: 0.3)) }) }),
    ("vacío", []),
]
for ex in VideoExercise.allCases {
    for (_, frames) in weird {
        switch VideoFormEngine.analyze(frames, exercise: ex) {
        case .success(let r):
            results += 1
            if !(0...100).contains(r.score) || r.issues.count > 3 || r.score.description.isEmpty { crashes += 1 }
            if r.reps.contains(where: { $0.end < $0.start }) { crashes += 1 }
        case .failure: results += 1
        }
    }
}
check(results == VideoExercise.allCases.count * weird.count && crashes == 0,
      "\(results) análisis raros, ninguno roto (nota 0–100, reps coherentes)")

print(failures == 0 ? "\nTODO OK" : "\n\(failures) FALLOS")
exit(failures == 0 ? 0 : 1)

infix operator |>
func |> <A, B>(a: A, f: (A) -> B) -> B { f(a) }
