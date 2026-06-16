import SwiftUI

// Drag-based horizontal ruler picker. Used for weight, height, age in
// the onboarding — feels closer to a physical dial than a stepper row.
struct SBRulerPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var tickSpacing: CGFloat = 9
    var majorTickEvery: Int = 10
    var tintColor: Color = .sbAccent

    @State private var dragAnchor: Double? = nil

    private var ticks: [Double] {
        stride(from: range.lowerBound, through: range.upperBound, by: step).map { $0 }
    }

    private var indexOfCurrent: Int {
        let idx = Int(round((value - range.lowerBound) / step))
        return min(max(idx, 0), ticks.count - 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                HStack(spacing: tickSpacing) {
                    ForEach(Array(ticks.enumerated()), id: \.offset) { idx, tick in
                        tickMark(idx: idx, value: tick)
                    }
                }
                .frame(height: 50)
                // Slide the tick row so the chosen value sits under the cursor.
                .offset(x: geo.size.width / 2 - CGFloat(indexOfCurrent) * tickSpacing)
                .animation(.easeOut(duration: 0.08), value: value)

                centerIndicator
            }
            .frame(width: geo.size.width, height: 64, alignment: .center)
            .contentShape(Rectangle())
            .clipped()
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { drag in
                        if dragAnchor == nil { dragAnchor = value }
                        let anchor = dragAnchor ?? value
                        let stepsMoved = -drag.translation.width / tickSpacing
                        let newValue = anchor + Double(stepsMoved) * step
                        let clamped = min(max(newValue, range.lowerBound), range.upperBound)
                        let snapped = (round(clamped / step) * step)
                        if abs(snapped - value) >= step / 2 {
                            HapticManager.selection()
                            value = snapped
                        }
                    }
                    .onEnded { _ in dragAnchor = nil }
            )
        }
        .frame(height: 64)
    }

    private func tickMark(idx: Int, value tick: Double) -> some View {
        let isMajor = idx % majorTickEvery == 0
        return VStack(spacing: 4) {
            Rectangle()
                .fill(Color.sbTextSecondary.opacity(isMajor ? 0.55 : 0.25))
                .frame(width: 1.5, height: isMajor ? 24 : 14)
            if isMajor {
                Text("\(Int(tick))")
                    .font(SBFont.label(11))
                    .foregroundColor(.sbTextSecondary.opacity(0.7))
                    .fixedSize()
            } else {
                Spacer().frame(height: 14)
            }
        }
        .frame(width: tickSpacing)
    }

    private var centerIndicator: some View {
        Rectangle()
            .fill(tintColor)
            .frame(width: 3, height: 38)
            .cornerRadius(1.5)
            .shadow(color: tintColor.opacity(0.5), radius: 6)
            .allowsHitTesting(false)
    }
}

// MARK: - BMI Indicator bar

struct SBBMIBar: View {
    let bmi: Double

    // Position of the marker on the 0...1 bar.
    private var position: Double {
        let clampedBMI = max(15, min(40, bmi))
        return (clampedBMI - 15) / (40 - 15)
    }

    private var label: LocalizedStringKey {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    private var markerColor: Color {
        switch bmi {
        case ..<18.5:   return .sbCyan
        case 18.5..<25: return .sbGreen
        case 25..<30:   return .orange
        default:        return .sbRed
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current BMI")
                    .font(SBFont.label())
                    .foregroundColor(.sbTextSecondary)
                Spacer()
                Text(LocalizedStringKey(stringValue))
                    .font(SBFont.label(11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(markerColor)
                    .cornerRadius(6)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Rainbow gradient track
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.sbCyan, .sbGreen, .orange, .sbRed],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(height: 8)

                    // Marker bubble showing the exact BMI number
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", bmi))
                            .font(SBFont.label(10))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(markerColor)
                            .cornerRadius(5)
                        Triangle()
                            .fill(markerColor)
                            .frame(width: 7, height: 5)
                    }
                    .offset(x: geo.size.width * position - 14, y: -10)
                    .animation(.easeOut(duration: 0.15), value: bmi)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Underweight")
                    .font(SBFont.label(10))
                    .foregroundColor(.sbTextSecondary)
                Spacer()
                Text("Normal")
                    .font(SBFont.label(10))
                    .foregroundColor(.sbTextSecondary)
                Spacer()
                Text("Overweight")
                    .font(SBFont.label(10))
                    .foregroundColor(.sbTextSecondary)
            }
            .padding(.top, 4)
        }
    }

    private var stringValue: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
