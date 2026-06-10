import SwiftUI

// Priority order:
// 1. Bundled MP4 video (Resources/ExerciseVideos/{id}.mp4)
// 2. 2-frame JPG animation from free-exercise-db (no API key needed)
// 3. Stick figure animation fallback
struct ExerciseAnimationView: View {
    let exercise: Exercise

    private var hasBundledVideo: Bool {
        Bundle.main.url(forResource: exercise.id, withExtension: "mp4") != nil
    }

    private var imageID: String? {
        ExerciseDatabase.imageIDs[exercise.id]
    }

    var body: some View {
        if hasBundledVideo {
            ExerciseVideoPlayer(videoName: exercise.id)
        } else if let id = imageID {
            ExerciseImageAnimView(imageID: id)
        } else {
            StickFigureView(exercise: exercise)
        }
    }
}

// MARK: - 2-frame exercise animation (yuhonas/free-exercise-db)
// Loads start + end-position JPGs and cross-fades between them,
// matching the look of Jefit / Hevy / Strong gym apps.

struct ExerciseImageAnimView: View {
    let imageID: String

    @State private var frames:  [UIImage] = []
    @State private var current  = 0
    @State private var loaded   = false

    private static let base =
        "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises"

    var body: some View {
        ZStack {
            Color.black  // universal dark bg keeps the look clean

            if !loaded {
                ProgressView().tint(.white.opacity(0.6))
            } else if frames.isEmpty {
                // fetch failed — caller should show stick figure instead,
                // but show a subtle placeholder just in case
                Image(systemName: "figure.strengthtraining.functional")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.2))
            } else {
                Image(uiImage: frames[current])
                    .resizable()
                    .scaledToFit()
                    .id(current)
                    .transition(.opacity.animation(.easeInOut(duration: 0.4)))
            }
        }
        .task(id: imageID) {
            await loadAndLoop()
        }
    }

    private func loadAndLoop() async {
        loaded  = false
        frames  = []
        current = 0

        // fetch both frames concurrently
        async let f0 = fetchImage(0)
        async let f1 = fetchImage(1)
        let result = await [f0, f1].compactMap { $0 }

        frames = result
        loaded = true

        guard frames.count > 1 else { return }

        // smooth flip loop — cancels automatically when view disappears
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(.easeInOut(duration: 0.35)) {
                current = (current + 1) % frames.count
            }
        }
    }

    private func fetchImage(_ index: Int) async -> UIImage? {
        guard let url = URL(string: "\(Self.base)/\(imageID)/\(index).jpg"),
              let (data, _) = try? await URLSession.shared.data(from: url)
        else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Stick figure fallback (Canvas-based, 60fps)

private struct StickFigureView: View {
    let exercise: Exercise

    private var animType: AnimType { AnimType.from(exercise) }

    var body: some View {
        TimelineView(.animation) { tl in
            let raw = tl.date.timeIntervalSinceReferenceDate
            let t   = CGFloat((sin(raw * animType.speed * .pi) + 1) * 0.5)
            Canvas { gc, size in
                animType.draw(gc, size, t)
            }
        }
    }
}

// MARK: - Animation types

private enum AnimType {
    case hangPull   // pull-up, lat-pulldown, hanging leg raise
    case squat      // squat, lunge
    case pressUp    // curl, overhead press, lateral raise
    case lyingPress // bench press
    case core       // crunch, plank, hip thrust
    case hinge      // deadlift, RDL
    case cardio     // jump rope, burpee, box jump

    var speed: Double {
        switch self {
        case .cardio: return 1.6
        case .core:   return 0.5
        default:      return 0.65
        }
    }

    static func from(_ ex: Exercise) -> AnimType {
        switch ex.id {
        case "pull_up", "lat_pulldown", "leg_raise":
            return .hangPull
        case "squat", "goblet_squat", "walking_lunge":
            return .squat
        case "barbell_curl", "hammer_curl", "lateral_raise",
             "overhead_press", "pike_push_up", "barbell_row",
             "dumbbell_row", "tricep_dip", "skull_crusher", "cable_fly":
            return .pressUp
        case "bench_press", "incline_dumbbell_press", "push_up":
            return .lyingPress
        case "plank", "crunch", "russian_twist",
             "glute_bridge", "hip_thrust":
            return .core
        case "deadlift", "romanian_deadlift":
            return .hinge
        default:
            switch ex.category {
            case .chest:            return .lyingPress
            case .back, .arms:      return .pressUp
            case .shoulders:        return .pressUp
            case .legs:             return .squat
            case .glutes, .core:    return .core
            case .cardio, .fullBody: return .cardio
            }
        }
    }

    // MARK: - Draw dispatcher
    func draw(_ gc: GraphicsContext, _ size: CGSize, _ t: CGFloat) {
        let w = size.width, h = size.height

        // Convert normalized → canvas point
        func pt(_ nx: CGFloat, _ ny: CGFloat) -> CGPoint { .init(x: w*nx, y: h*ny) }
        // Lerp between two normalized coords using t
        func lp(_ ax: CGFloat, _ ay: CGFloat,
                _ bx: CGFloat, _ by: CGFloat) -> CGPoint {
            pt(ax + (bx-ax)*t, ay + (by-ay)*t)
        }

        let lw: CGFloat  = 3.8          // limb line width
        let hr: CGFloat  = w * 0.09     // head radius

        func line(_ a: CGPoint, _ b: CGPoint,
                  _ color: Color = .sbAccent, _ width: CGFloat = lw) {
            var p = Path(); p.move(to: a); p.addLine(to: b)
            gc.stroke(p, with: .color(color),
                      style: StrokeStyle(lineWidth: width, lineCap: .round,
                                         lineJoin: .round))
        }
        func circle(_ c: CGPoint, _ r: CGFloat, _ color: Color = .sbAccent) {
            let rect = CGRect(x: c.x-r, y: c.y-r, width: r*2, height: r*2)
            gc.fill(Path(ellipseIn: rect), with: .color(color))
        }
        // Draw full standing figure from pre-computed joint points
        func standingFigure(head: CGPoint, neck: CGPoint,
                            lSh: CGPoint, rSh: CGPoint,
                            lEl: CGPoint, rEl: CGPoint,
                            lHand: CGPoint, rHand: CGPoint,
                            hip: CGPoint,
                            lKnee: CGPoint, rKnee: CGPoint,
                            lFoot: CGPoint, rFoot: CGPoint) {
            circle(head, hr * 0.85)
            line(neck, hip)
            line(lSh, neck); line(rSh, neck)
            line(lSh, lEl); line(lEl, lHand)
            line(rSh, rEl); line(rEl, rHand)
            line(hip, lKnee); line(lKnee, lFoot)
            line(hip, rKnee); line(rKnee, rFoot)
        }

        switch self {

        // ── Hang / Pull ─────────────────────────────────────────────
        case .hangPull:
            // Horizontal bar at top
            line(pt(0.18, 0.05), pt(0.82, 0.05), .sbBorder, 5)
            // Grip points
            let lGrip = pt(0.40, 0.07)
            let rGrip = pt(0.60, 0.07)
            circle(lGrip, 4); circle(rGrip, 4)
            // Head — rises as t→1 (pull-up motion)
            let headY: CGFloat = 0.26 - t * 0.09
            let head  = pt(0.50, headY)
            let neck  = pt(0.50, headY + 0.08)
            // Upper arms go from grip down to shoulders
            let lSh   = pt(0.40, headY + 0.14)
            let rSh   = pt(0.60, headY + 0.14)
            let lEl   = pt(0.40, headY + 0.06)  // elbow mid-arm
            let rEl   = pt(0.60, headY + 0.06)
            let hip   = pt(0.50, headY + 0.32)
            // Legs animate: hanging down (t=0) → raised (t=1)
            let lKnee = lp(0.46, headY+0.32+0.22,   0.36, headY+0.32-0.10)
            let rKnee = lp(0.54, headY+0.32+0.22,   0.64, headY+0.32-0.10)
            let lFoot = lp(0.45, headY+0.32+0.42,   0.30, headY+0.32-0.18)
            let rFoot = lp(0.55, headY+0.32+0.42,   0.70, headY+0.32-0.18)

            circle(head, hr * 0.80)
            line(lGrip, lEl); line(lEl, lSh)
            line(rGrip, rEl); line(rEl, rSh)
            line(lSh, neck); line(rSh, neck)
            line(neck, hip)
            line(hip, lKnee); line(lKnee, lFoot)
            line(hip, rKnee); line(rKnee, rFoot)

        // ── Squat ────────────────────────────────────────────────────
        case .squat:
            // Feet stay planted
            let lFoot = pt(0.37, 0.87)
            let rFoot = pt(0.63, 0.87)
            // All other joints lerp down as t→1
            let head  = lp(0.50, 0.07,   0.50, 0.30)
            let neck  = lp(0.50, 0.15,   0.50, 0.38)
            let lSh   = lp(0.39, 0.21,   0.37, 0.44)
            let rSh   = lp(0.61, 0.21,   0.63, 0.44)
            let lEl   = lp(0.36, 0.38,   0.31, 0.57)
            let rEl   = lp(0.64, 0.38,   0.69, 0.57)
            let lHand = lp(0.37, 0.52,   0.32, 0.67)
            let rHand = lp(0.63, 0.52,   0.68, 0.67)
            let hip   = lp(0.50, 0.47,   0.50, 0.62)
            let lKnee = lp(0.43, 0.65,   0.34, 0.74)
            let rKnee = lp(0.57, 0.65,   0.66, 0.74)
            // Ground line
            line(pt(0.15, 0.90), pt(0.85, 0.90), .sbBorder, 2)
            standingFigure(head: head, neck: neck, lSh: lSh, rSh: rSh,
                           lEl: lEl, rEl: rEl, lHand: lHand, rHand: rHand,
                           hip: hip, lKnee: lKnee, rKnee: rKnee,
                           lFoot: lFoot, rFoot: rFoot)

        // ── Press Up / Arm Work ──────────────────────────────────────
        case .pressUp:
            // Standing — arms move from sides (t=0) to raised (t=1)
            let head  = pt(0.50, 0.08)
            let neck  = pt(0.50, 0.17)
            let lSh   = pt(0.38, 0.23)
            let rSh   = pt(0.62, 0.23)
            let hip   = pt(0.50, 0.51)
            let lKnee = pt(0.44, 0.68)
            let rKnee = pt(0.56, 0.68)
            let lFoot = pt(0.41, 0.86)
            let rFoot = pt(0.59, 0.86)
            // Arms: sides → overhead
            let lEl   = lp(0.31, 0.40,   0.34, 0.18)
            let rEl   = lp(0.69, 0.40,   0.66, 0.18)
            let lHand = lp(0.29, 0.54,   0.36, 0.05)
            let rHand = lp(0.71, 0.54,   0.64, 0.05)
            line(pt(0.15, 0.89), pt(0.85, 0.89), .sbBorder, 2)
            standingFigure(head: head, neck: neck, lSh: lSh, rSh: rSh,
                           lEl: lEl, rEl: rEl, lHand: lHand, rHand: rHand,
                           hip: hip, lKnee: lKnee, rKnee: rKnee,
                           lFoot: lFoot, rFoot: rFoot)

        // ── Lying Press / Push-Up ────────────────────────────────────
        case .lyingPress:
            // Side view: person lying, one arm pushes up and down
            let bodyY: CGFloat = 0.60
            // Ground / bench
            line(pt(0.08, bodyY + 0.12), pt(0.92, bodyY + 0.12), .sbBorder, 3)
            // Head (left side)
            let head = pt(0.13, bodyY)
            circle(head, hr * 0.72)
            // Torso horizontal
            let torsoEnd = pt(0.70, bodyY)
            line(pt(0.18, bodyY), torsoEnd)
            // Legs
            line(torsoEnd, pt(0.82, bodyY - 0.05))  // thigh up slightly (feet on floor/bench)
            line(pt(0.82, bodyY - 0.05), pt(0.87, bodyY + 0.10))
            // Arms: go from down (t=0) to up (t=1)
            let armUp = t * 0.35
            let shoulder = pt(0.30, bodyY)
            let elbow    = pt(0.28, bodyY - 0.12 - armUp)
            let hand     = pt(0.30, bodyY - 0.24 - armUp * 1.6)
            line(shoulder, elbow); line(elbow, hand)
            // Show second arm hint (other side)
            line(pt(0.36, bodyY), pt(0.34, bodyY - 0.07 - armUp * 0.7),
                 .sbAccent.opacity(0.4))
            line(pt(0.34, bodyY - 0.07 - armUp * 0.7),
                 pt(0.36, bodyY - 0.14 - armUp * 1.3),
                 .sbAccent.opacity(0.4))

        // ── Core / Floor ─────────────────────────────────────────────
        case .core:
            let floorY: CGFloat = 0.86
            // Floor line
            line(pt(0.08, floorY + 0.04), pt(0.92, floorY + 0.04), .sbBorder, 2)
            // Legs stay bent on floor
            let hip   = pt(0.50, floorY - 0.02)
            let lKnee = pt(0.36, floorY - 0.22)
            let rKnee = pt(0.64, floorY - 0.22)
            let lFoot = pt(0.33, floorY + 0.01)
            let rFoot = pt(0.67, floorY + 0.01)
            // Upper body rises with crunch (t=0 flat → t=1 crunched)
            let rise = t * 0.28
            let neck  = pt(0.50, floorY - 0.10 - rise)
            let lSh   = pt(0.37, floorY - 0.06 - rise)
            let rSh   = pt(0.63, floorY - 0.06 - rise)
            let head  = pt(0.50, floorY - 0.20 - rise)
            // Hands behind head
            let lHand = pt(0.42, floorY - 0.22 - rise * 0.6)
            let rHand = pt(0.58, floorY - 0.22 - rise * 0.6)
            let lEl   = pt(0.33, floorY - 0.04 - rise)
            let rEl   = pt(0.67, floorY - 0.04 - rise)

            circle(head, hr * 0.75)
            line(neck, hip)
            line(lSh, neck); line(rSh, neck)
            line(lSh, lEl); line(lEl, lHand)
            line(rSh, rEl); line(rEl, rHand)
            line(hip, lKnee); line(lKnee, lFoot)
            line(hip, rKnee); line(rKnee, rFoot)

        // ── Hinge / Deadlift ─────────────────────────────────────────
        case .hinge:
            // Standing (t=0) → hinge forward (t=1)
            let lFoot = pt(0.36, 0.87)
            let rFoot = pt(0.64, 0.87)
            let head  = lp(0.50, 0.07,   0.24, 0.38)
            let neck  = lp(0.50, 0.15,   0.29, 0.43)
            let lSh   = lp(0.38, 0.21,   0.17, 0.38)
            let rSh   = lp(0.62, 0.21,   0.41, 0.38)
            // Arms hang straight toward bar on floor
            let lEl   = lp(0.37, 0.37,   0.20, 0.53)
            let rEl   = lp(0.63, 0.37,   0.44, 0.53)
            let lHand = lp(0.37, 0.52,   0.22, 0.68)
            let rHand = lp(0.63, 0.52,   0.46, 0.68)
            let hip   = lp(0.50, 0.47,   0.56, 0.52)
            let lKnee = lp(0.43, 0.65,   0.42, 0.68)
            let rKnee = lp(0.57, 0.65,   0.60, 0.68)
            // Bar on floor (visible when t→1)
            let barOpacity = Double(t) * 0.9
            line(pt(0.14, 0.87), pt(0.86, 0.87), .sbBorder, 2)
            let barColor = Color.sbAccent.opacity(barOpacity * 0.6)
            line(lHand, rHand, barColor, 5)       // barbell
            circle(lHand, 5, barColor)
            circle(rHand, 5, barColor)

            standingFigure(head: head, neck: neck, lSh: lSh, rSh: rSh,
                           lEl: lEl, rEl: rEl, lHand: lHand, rHand: rHand,
                           hip: hip, lKnee: lKnee, rKnee: rKnee,
                           lFoot: lFoot, rFoot: rFoot)

        // ── Cardio / Jump ────────────────────────────────────────────
        case .cardio:
            let jump = t * 0.20  // how high off ground
            let head  = pt(0.50, 0.08 - jump)
            let neck  = pt(0.50, 0.16 - jump)
            let lSh   = pt(0.38, 0.22 - jump)
            let rSh   = pt(0.62, 0.22 - jump)
            let hip   = pt(0.50, 0.50 - jump)
            // Arms swing with jump
            let sw = (t - 0.5) * 0.28
            let lEl   = pt(0.30 - sw, 0.38 - jump)
            let rEl   = pt(0.70 + sw, 0.38 - jump)
            let lHand = pt(0.26 - sw*1.4, 0.52 - jump)
            let rHand = pt(0.74 + sw*1.4, 0.52 - jump)
            // Legs: spread on landing, together at peak
            let lg = (1 - t) * 0.12
            let lKnee = pt(0.42 - lg, 0.66 - jump * 0.6)
            let rKnee = pt(0.58 + lg, 0.66 - jump * 0.6)
            let lFoot = pt(0.39 - lg, 0.84 - jump * 0.4)
            let rFoot = pt(0.61 + lg, 0.84 - jump * 0.4)
            // Ground
            line(pt(0.15, 0.88), pt(0.85, 0.88), .sbBorder, 2)
            standingFigure(head: head, neck: neck, lSh: lSh, rSh: rSh,
                           lEl: lEl, rEl: rEl, lHand: lHand, rHand: rHand,
                           hip: hip, lKnee: lKnee, rKnee: rKnee,
                           lFoot: lFoot, rFoot: rFoot)
        }
    }
}
