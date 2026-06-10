import SwiftUI

// Animated muscle-highlight body diagram.
// Shows a front-view body silhouette and highlights which
// muscles are active (primary = bright, secondary = dim).
struct MuscleBodyView: View {
    let category: MuscleGroup
    let secondaryMuscles: [String]

    var body: some View {
        TimelineView(.animation) { ctx in
            // t oscillates 0→1→0 at ~0.9 Hz for the pulsing glow
            let t = CGFloat((sin(ctx.date.timeIntervalSinceReferenceDate * 1.8) + 1) * 0.5)
            Canvas { gc, size in
                draw(ctx: gc, w: size.width, h: size.height, pulse: t)
            }
        }
    }

    // MARK: - Drawing

    private func draw(ctx: GraphicsContext, w: CGFloat, h: CGFloat, pulse: CGFloat) {
        // All positions are in a normalised 1×1 space
        let cx = w / 2

        // ── base body parts ────────────────────────────────────
        let base = Color(hex: "#2A2A2A")

        // head
        let headR: CGFloat = w * 0.13
        fill(ctx, ellipse: CGRect(x: cx - headR, y: h * 0.01,
                                  width: headR * 2, height: headR * 2),
             color: base, radius: headR)

        // neck
        fill(ctx, rect: CGRect(x: cx - w * 0.055, y: h * 0.14,
                               width: w * 0.11, height: h * 0.05), color: base, radius: 3)

        // torso
        fill(ctx, rect: CGRect(x: cx - w * 0.23, y: h * 0.185,
                               width: w * 0.46, height: h * 0.33), color: base, radius: 8)

        // hips
        fill(ctx, rect: CGRect(x: cx - w * 0.205, y: h * 0.505,
                               width: w * 0.41, height: h * 0.095), color: base, radius: 6)

        // left upper-arm
        fill(ctx, rect: CGRect(x: cx - w * 0.41, y: h * 0.195,
                               width: w * 0.13, height: h * 0.205), color: base, radius: 6)
        // left forearm
        fill(ctx, rect: CGRect(x: cx - w * 0.40, y: h * 0.41,
                               width: w * 0.115, height: h * 0.18), color: base, radius: 6)

        // right upper-arm
        fill(ctx, rect: CGRect(x: cx + w * 0.28, y: h * 0.195,
                               width: w * 0.13, height: h * 0.205), color: base, radius: 6)
        // right forearm
        fill(ctx, rect: CGRect(x: cx + w * 0.285, y: h * 0.41,
                               width: w * 0.115, height: h * 0.18), color: base, radius: 6)

        // left thigh
        fill(ctx, rect: CGRect(x: cx - w * 0.215, y: h * 0.595,
                               width: w * 0.185, height: h * 0.235), color: base, radius: 8)
        // left calf
        fill(ctx, rect: CGRect(x: cx - w * 0.205, y: h * 0.838,
                               width: w * 0.165, height: h * 0.155), color: base, radius: 6)

        // right thigh
        fill(ctx, rect: CGRect(x: cx + w * 0.03, y: h * 0.595,
                               width: w * 0.185, height: h * 0.235), color: base, radius: 8)
        // right calf
        fill(ctx, rect: CGRect(x: cx + w * 0.04, y: h * 0.838,
                               width: w * 0.165, height: h * 0.155), color: base, radius: 6)

        // ── muscle highlights ──────────────────────────────────
        let bright = Color.sbAccent.opacity(0.55 + 0.45 * pulse)
        highlightMuscle(ctx: ctx, w: w, h: h, category: category, color: bright, pulse: pulse)
    }

    private func highlightMuscle(ctx: GraphicsContext, w: CGFloat, h: CGFloat,
                                  category: MuscleGroup, color: Color, pulse: CGFloat) {
        let cx = w / 2
        switch category {
        case .chest:
            // pecs — upper-mid torso split
            fill(ctx, rect: CGRect(x: cx - w * 0.22, y: h * 0.195,
                                   width: w * 0.20, height: h * 0.13), color: color, radius: 5)
            fill(ctx, rect: CGRect(x: cx + w * 0.02, y: h * 0.195,
                                   width: w * 0.20, height: h * 0.13), color: color, radius: 5)

        case .back:
            // lats — wide torso
            fill(ctx, rect: CGRect(x: cx - w * 0.225, y: h * 0.22,
                                   width: w * 0.175, height: h * 0.22), color: color, radius: 5)
            fill(ctx, rect: CGRect(x: cx + w * 0.05, y: h * 0.22,
                                   width: w * 0.175, height: h * 0.22), color: color, radius: 5)

        case .shoulders:
            // deltoids
            fill(ctx, rect: CGRect(x: cx - w * 0.405, y: h * 0.195,
                                   width: w * 0.13, height: h * 0.09), color: color, radius: 6)
            fill(ctx, rect: CGRect(x: cx + w * 0.28, y: h * 0.195,
                                   width: w * 0.13, height: h * 0.09), color: color, radius: 6)

        case .arms:
            // biceps
            fill(ctx, rect: CGRect(x: cx - w * 0.40, y: h * 0.20,
                                   width: w * 0.13, height: h * 0.20), color: color, radius: 6)
            fill(ctx, rect: CGRect(x: cx + w * 0.28, y: h * 0.20,
                                   width: w * 0.13, height: h * 0.20), color: color, radius: 6)
            // triceps (slightly dimmer)
            let dim = Color.sbAccent.opacity(0.25 + 0.3 * pulse)
            fill(ctx, rect: CGRect(x: cx - w * 0.395, y: h * 0.41,
                                   width: w * 0.115, height: h * 0.09), color: dim, radius: 5)
            fill(ctx, rect: CGRect(x: cx + w * 0.285, y: h * 0.41,
                                   width: w * 0.115, height: h * 0.09), color: dim, radius: 5)

        case .core:
            // abs — centre of torso
            fill(ctx, rect: CGRect(x: cx - w * 0.13, y: h * 0.31,
                                   width: w * 0.26, height: h * 0.19), color: color, radius: 5)

        case .legs:
            // quads
            fill(ctx, rect: CGRect(x: cx - w * 0.21, y: h * 0.595,
                                   width: w * 0.185, height: h * 0.23), color: color, radius: 8)
            fill(ctx, rect: CGRect(x: cx + w * 0.03, y: h * 0.595,
                                   width: w * 0.185, height: h * 0.23), color: color, radius: 8)

        case .glutes:
            // hip area
            fill(ctx, rect: CGRect(x: cx - w * 0.20, y: h * 0.505,
                                   width: w * 0.41, height: h * 0.095), color: color, radius: 6)

        case .cardio:
            // heart area + legs (general cardio)
            fill(ctx, rect: CGRect(x: cx - w * 0.08, y: h * 0.21,
                                   width: w * 0.16, height: h * 0.12), color: color, radius: 5)
            fill(ctx, rect: CGRect(x: cx - w * 0.21, y: h * 0.595,
                                   width: w * 0.185, height: h * 0.235), color: color.opacity(0.7), radius: 8)
            fill(ctx, rect: CGRect(x: cx + w * 0.03, y: h * 0.595,
                                   width: w * 0.185, height: h * 0.235), color: color.opacity(0.7), radius: 8)

        case .fullBody:
            // Everything lit up
            let c = color.opacity(0.6)
            fill(ctx, rect: CGRect(x: cx - w * 0.22, y: h * 0.195, width: w * 0.44, height: h * 0.31), color: c, radius: 6)
            fill(ctx, rect: CGRect(x: cx - w * 0.40, y: h * 0.20, width: w * 0.13, height: h * 0.39), color: c, radius: 6)
            fill(ctx, rect: CGRect(x: cx + w * 0.28, y: h * 0.20, width: w * 0.13, height: h * 0.39), color: c, radius: 6)
            fill(ctx, rect: CGRect(x: cx - w * 0.21, y: h * 0.595, width: w * 0.185, height: h * 0.39), color: c, radius: 8)
            fill(ctx, rect: CGRect(x: cx + w * 0.03, y: h * 0.595, width: w * 0.185, height: h * 0.39), color: c, radius: 8)
        }
    }

    // MARK: - Helpers

    private func fill(_ ctx: GraphicsContext, rect: CGRect, color: Color, radius: CGFloat) {
        let path = Path(roundedRect: rect, cornerRadius: radius)
        ctx.fill(path, with: .color(color))
    }

    private func fill(_ ctx: GraphicsContext, ellipse rect: CGRect, color: Color, radius: CGFloat) {
        let path = Path(ellipseIn: rect)
        ctx.fill(path, with: .color(color))
    }
}

// MARK: - Preview helper
struct MuscleBodyView_Previews: PreviewProvider {
    static var previews: some View {
        MuscleBodyView(category: .chest, secondaryMuscles: [])
            .frame(width: 120, height: 240)
            .background(Color.sbBackground)
    }
}
