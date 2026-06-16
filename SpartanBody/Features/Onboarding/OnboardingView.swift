import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var profile = UserProfile.shared
    @State private var step = 0
    private let totalSteps = 5

    var body: some View {
        ZStack {
            Color.sbBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 60)
                    .padding(.horizontal, 28)

                Spacer()

                Group {
                    switch step {
                    case 0: WelcomeStep()
                    case 1: GoalStep()
                    case 2: PersonalStep()
                    case 3: ActivityStep()
                    default: SummaryStep(onDone: finishOnboarding)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step)

                Spacer()

                if step < totalSteps - 1 {
                    navigationButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
            }
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<(totalSteps - 1), id: \.self) { i in
                Capsule()
                    .fill(i < step ? Color.sbAccent : (i == step ? Color.sbAccent.opacity(0.5) : Color.sbBorder))
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
            }
        }
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        VStack(spacing: 12) {
            SBPrimaryButton(title: step == 3 ? "See My Plan" : "Continue") {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { step += 1 }
                HapticManager.light()
            }

            if step > 0 {
                Button("Back") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { step -= 1 }
                    HapticManager.selection()
                }
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
            }
        }
    }

    private func finishOnboarding() {
        HapticManager.heavy()
        withAnimation(.spring(response: 0.5)) {
            profile.onboardingDone = true
        }
    }
}

// MARK: - Step 0: Welcome

private struct WelcomeStep: View {
    @State private var appeared = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                // Pulsing background circles
                ForEach([0.8, 1.0, 1.2], id: \.self) { scale in
                    Circle()
                        .fill(Color.sbAccent.opacity(0.06))
                        .frame(width: 180, height: 180)
                        .scaleEffect(pulse ? scale * 1.15 : scale)
                        .animation(
                            .easeInOut(duration: 2.2).repeatForever(autoreverses: true)
                                .delay((scale - 0.8) * 0.4),
                            value: pulse
                        )
                }

                Circle()
                    .fill(Color.sbAccentDim)
                    .frame(width: 130, height: 130)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .animation(.spring(response: 0.7, dampingFraction: 0.6), value: appeared)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 56, weight: .black))
                    .foregroundColor(.sbAccent)
                    .scaleEffect(appeared ? 1 : 0.2)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.15), value: appeared)
            }
            .frame(height: 220)

            VStack(spacing: 14) {
                Text("SPARTAN BODY")
                    .font(SBFont.display(38))
                    .foregroundColor(.sbTextPrimary)
                    .tracking(4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25), value: appeared)

                Text("Workouts · Nutrition · Challenges\nAll in one place, completely free.")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.38), value: appeared)
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            appeared = true
            pulse = true
        }
    }
}

// MARK: - Step 1: Goal

private struct GoalStep: View {
    @ObservedObject private var profile = UserProfile.shared

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("What's Your Goal?")
                    .font(SBFont.display(30))
                    .foregroundColor(.sbTextPrimary)
                Text("We'll personalize your plan for you")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
            }

            VStack(spacing: 12) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    GoalCard(goal: goal, isSelected: profile.goal == goal) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            profile.goal = goal
                        }
                        HapticManager.selection()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.sbAccent : Color.sbSurfaceRaised)
                        .frame(width: 50, height: 50)
                    Image(systemName: goal.icon)
                        .foregroundColor(isSelected ? .white : .sbTextSecondary)
                        .font(.system(size: 20, weight: .bold))
                }
                .scaleEffect(isSelected ? 1.05 : 1.0)

                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(goal.rawValue))
                        .font(SBFont.heading(17))
                        .foregroundColor(isSelected ? .sbAccent : .sbTextPrimary)
                    Text(LocalizedStringKey(goal.description))
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .sbAccent : .sbBorder)
                    .font(.system(size: 22))
            }
            .padding(16)
            .background(isSelected ? Color.sbAccentDim : Color.sbSurface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.sbAccent : Color.sbBorder, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Personal Info

private struct PersonalStep: View {
    @ObservedObject private var profile = UserProfile.shared
    @State private var nameText = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text("About You")
                        .font(SBFont.display(30))
                        .foregroundColor(.sbTextPrimary)
                    Text("Needed to calculate your daily targets")
                        .font(SBFont.body())
                        .foregroundColor(.sbTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    Label("Name", systemImage: "person")
                        .font(SBFont.label())
                        .foregroundColor(.sbTextSecondary)
                    TextField("Your name", text: $nameText)
                        .font(SBFont.body())
                        .foregroundColor(.sbTextPrimary)
                        .padding(14)
                        .background(Color.sbSurface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
                        .onChange(of: nameText) { profile.name = $0 }
                }

                // Age
                VStack(alignment: .leading, spacing: 6) {
                    Label("Age", systemImage: "calendar")
                        .font(SBFont.label())
                        .foregroundColor(.sbTextSecondary)
                    HStack {
                        Spacer()
                        Text("\(profile.age)")
                            .font(SBFont.display(48))
                            .foregroundColor(.sbTextPrimary)
                            .monospacedDigit()
                        Text("yrs")
                            .font(SBFont.body())
                            .foregroundColor(.sbTextSecondary)
                            .offset(y: 6)
                        Spacer()
                    }
                    SBRulerPicker(
                        value: Binding(
                            get: { Double(profile.age) },
                            set: { profile.age = Int($0) }
                        ),
                        range: 13...90, step: 1, majorTickEvery: 5
                    )
                }
                .padding(16)
                .background(Color.sbSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))

                // Weight + BMI bar (the hero card)
                VStack(alignment: .leading, spacing: 10) {
                    Label("Weight", systemImage: "scalemass")
                        .font(SBFont.label())
                        .foregroundColor(.sbTextSecondary)
                    HStack {
                        Spacer()
                        Text(String(format: "%.0f", profile.weightKg))
                            .font(SBFont.display(56))
                            .foregroundColor(.sbTextPrimary)
                            .monospacedDigit()
                        Text("kg")
                            .font(SBFont.heading(18))
                            .foregroundColor(.sbTextSecondary)
                            .offset(y: 10)
                        Spacer()
                    }
                    SBRulerPicker(
                        value: $profile.weightKg,
                        range: 30...250, step: 1, majorTickEvery: 10
                    )
                    Divider().background(Color.sbBorder).padding(.vertical, 6)
                    SBBMIBar(bmi: profile.bmi)
                }
                .padding(16)
                .background(Color.sbSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))

                // Height
                VStack(alignment: .leading, spacing: 6) {
                    Label("Height", systemImage: "ruler")
                        .font(SBFont.label())
                        .foregroundColor(.sbTextSecondary)
                    HStack {
                        Spacer()
                        Text(String(format: "%.0f", profile.heightCm))
                            .font(SBFont.display(48))
                            .foregroundColor(.sbTextPrimary)
                            .monospacedDigit()
                        Text("cm")
                            .font(SBFont.body())
                            .foregroundColor(.sbTextSecondary)
                            .offset(y: 6)
                        Spacer()
                    }
                    SBRulerPicker(
                        value: $profile.heightCm,
                        range: 100...230, step: 1, majorTickEvery: 10
                    )
                }
                .padding(16)
                .background(Color.sbSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .onAppear { nameText = profile.name }
    }
}

private struct StepperRow: View {
    let label: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.sbSurfaceRaised)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.sbAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(label))
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(step < 1 ? String(format: "%.1f", value) : "\(Int(value))")
                        .font(SBFont.heading(20))
                        .foregroundColor(.sbTextPrimary)
                        .monospacedDigit()
                    Text(unit)
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }
            }

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if value - step >= range.lowerBound {
                        value -= step
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.sbTextPrimary)
                        .frame(width: 40, height: 40)
                }

                Divider().frame(height: 20)

                Button {
                    if value + step <= range.upperBound {
                        value += step
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.sbTextPrimary)
                        .frame(width: 40, height: 40)
                }
            }
            .background(Color.sbSurfaceRaised)
            .cornerRadius(10)
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
    }
}

// MARK: - Step 3: Activity Level

private struct ActivityStep: View {
    @ObservedObject private var profile = UserProfile.shared

    private let details: [ActivityLevel: (icon: String, detail: String)] = [
        .sedentary: ("house.fill", "Office job, little to no exercise"),
        .light:     ("figure.walk", "Light exercise 1–3 days/week"),
        .moderate:  ("figure.run",  "Moderate exercise 3–5 days/week"),
        .active:    ("figure.strengthtraining.traditional", "Hard exercise 6–7 days/week"),
    ]

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Activity Level")
                    .font(SBFont.display(30))
                    .foregroundColor(.sbTextPrimary)
                Text("Helps us estimate how many calories you burn")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    let info = details[level] ?? ("figure.walk", "")
                    ActivityCard(
                        level: level,
                        icon: info.icon,
                        detail: info.detail,
                        isSelected: profile.activityLevel == level
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            profile.activityLevel = level
                        }
                        HapticManager.selection()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct ActivityCard: View {
    let level: ActivityLevel
    let icon: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.sbAccent : Color.sbSurfaceRaised)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .foregroundColor(isSelected ? .white : .sbTextSecondary)
                        .font(.system(size: 20, weight: .semibold))
                }
                .scaleEffect(isSelected ? 1.05 : 1.0)

                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(level.rawValue))
                        .font(SBFont.heading(15))
                        .foregroundColor(isSelected ? .sbAccent : .sbTextPrimary)
                    Text(LocalizedStringKey(detail))
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .sbAccent : .sbBorder)
                    .font(.system(size: 20))
            }
            .padding(14)
            .background(isSelected ? Color.sbAccentDim : Color.sbSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.sbAccent : Color.sbBorder, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 4: Summary

private struct SummaryStep: View {
    @ObservedObject private var profile = UserProfile.shared
    let onDone: () -> Void
    @State private var appeared = false

    private var proteinCals: Int { profile.dailyProteinTarget * 4 }
    private var fatTarget: Int { Int(Double(profile.dailyCalorieTarget) * 0.25 / 9) }
    private var carbTarget: Int { Int(Double(profile.dailyCalorieTarget) * 0.45 / 4) }

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text(profile.name.isEmpty ? "You're all set!" : "You're all set, \(profile.name)!")
                    .font(SBFont.display(28))
                    .foregroundColor(.sbTextPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)

                Text("Here's your personalised daily plan")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.1), value: appeared)
            }

            // Calorie card
            VStack(spacing: 6) {
                Text("\(profile.dailyCalorieTarget)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundColor(.sbAccent)
                    .monospacedDigit()
                    .scaleEffect(appeared ? 1 : 0.6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.18), value: appeared)
                Text("daily calories")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.22), value: appeared)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.sbAccentDim)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.sbAccent.opacity(0.3), lineWidth: 1.5))

            // Macros row
            HStack(spacing: 12) {
                MacroPill(value: profile.dailyProteinTarget, unit: "g", label: "Protein", color: .sbAccent)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(0.28), value: appeared)
                MacroPill(value: carbTarget, unit: "g", label: "Carbs", color: .sbGreen)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(0.34), value: appeared)
                MacroPill(value: fatTarget, unit: "g", label: "Fat", color: Color.orange)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(0.40), value: appeared)
            }

            // Goal badge
            HStack(spacing: 10) {
                Image(systemName: profile.goal.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.sbAccent)
                Text(NSLocalizedString(profile.goal.rawValue, comment: "") + " · " + NSLocalizedString(profile.activityLevel.rawValue, comment: ""))
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.sbSurface)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.sbBorder))
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5).delay(0.46), value: appeared)

            SBPrimaryButton(title: "Start My Journey") { onDone() }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.5).delay(0.52), value: appeared)
        }
        .padding(.horizontal, 24)
        .onAppear { appeared = true }
    }
}

private struct MacroPill: View {
    let value: Int
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(SBFont.heading(18))
                .foregroundColor(color)
                .monospacedDigit()
            Text(LocalizedStringKey(label))
                .font(SBFont.label(11))
                .foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.1))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.25), lineWidth: 1))
    }
}
