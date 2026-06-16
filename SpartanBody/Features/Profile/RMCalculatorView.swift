import SwiftUI

// Repetition Maximum calculator using the Epley formula.
// Given a weight you lifted for R reps, estimate your max for any rep count.
struct RMCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weight: String = ""
    @State private var reps: String = ""

    private let repTargets: [Int] = [1, 3, 5, 7, 9, 12, 15, 20]

    private var inputWeight: Double { Double(weight.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var inputReps:   Int    { Int(reps) ?? 0 }

    // 1RM = weight × (1 + reps/30)
    private var oneRepMax: Double {
        guard inputWeight > 0, inputReps > 0 else { return 0 }
        return inputWeight * (1.0 + Double(inputReps) / 30.0)
    }

    // weightForReps = 1RM / (1 + targetReps/30)
    private func weight(forReps r: Int) -> Double {
        guard oneRepMax > 0 else { return 0 }
        return oneRepMax / (1.0 + Double(r) / 30.0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        inputCard
                        if oneRepMax > 0 {
                            resultsGrid
                        } else {
                            placeholderGrid
                        }
                        whatIsRMCard
                        howToChooseCard
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle(Text("RM Calculator"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.sbAccent)
                    }
                }
            }
        }
    }

    // MARK: - Input card

    private var inputCard: some View {
        SBCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your last set")
                    .font(SBFont.heading(16))
                    .foregroundColor(.sbTextPrimary)

                HStack(spacing: 12) {
                    inputField(label: "Weight (kg)", text: $weight)
                    inputField(label: "Reps", text: $reps)
                }
            }
        }
    }

    private func inputField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(label))
                .font(SBFont.label())
                .foregroundColor(.sbTextSecondary)
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .font(SBFont.heading(20))
                .foregroundColor(.sbTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.sbSurfaceRaised)
                .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Results

    private var resultsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(repTargets, id: \.self) { r in
                resultCell(reps: r, weight: weight(forReps: r))
            }
        }
    }

    private var placeholderGrid: some View {
        VStack(spacing: 10) {
            Image(systemName: "scalemass")
                .font(.system(size: 32))
                .foregroundColor(.sbTextSecondary.opacity(0.4))
            Text("Enter a weight and the reps you can do to see your estimated maxes.")
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.sbSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
    }

    private func resultCell(reps: Int, weight: Double) -> some View {
        let isHighlight = reps == 1
        return VStack(spacing: 4) {
            Text("\(reps)RM")
                .font(SBFont.label(11))
                .foregroundColor(isHighlight ? .white : .sbAccent)
            Text(String(format: "%.1f", weight))
                .font(SBFont.heading(18))
                .foregroundColor(isHighlight ? .white : .sbTextPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            isHighlight
                ? AnyShapeStyle(LinearGradient.sbAccentGradient)
                : AnyShapeStyle(Color.sbSurface)
        )
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(isHighlight ? Color.clear : Color.sbBorder, lineWidth: 1))
        .shadow(color: isHighlight ? Color.sbAccent.opacity(0.3) : .clear, radius: 6, y: 2)
    }

    // MARK: - Info cards

    private var whatIsRMCard: some View {
        SBCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("What is RM?")
                    .font(SBFont.heading(16))
                    .foregroundColor(.sbTextPrimary)
                Text("RM (Repetition Maximum) is the maximum weight you can lift for a specific number of repetitions with proper form.")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .lineSpacing(3)
                VStack(alignment: .leading, spacing: 6) {
                    bullet("1RM: the maximum weight you can lift for one rep.")
                    bullet("5RM: the maximum weight you can lift for five reps.")
                }
                .padding(.top, 2)
            }
        }
    }

    private var howToChooseCard: some View {
        SBCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("How to choose weight and reps")
                    .font(SBFont.heading(16))
                    .foregroundColor(.sbTextPrimary)
                Text("If you're new to fitness or lack experience, start with lighter weights and more reps to practice proper form and feel the muscle engagement.")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .lineSpacing(3)
                Text("As you progress, gradually increase weight and lower reps to keep challenging your strength.")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .lineSpacing(3)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Color.sbAccent).frame(width: 6, height: 6).padding(.top, 7)
            Text(LocalizedStringKey(text))
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
