import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var profile = UserProfile.shared
    @State private var step = 0
    private let totalSteps = 7

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
                    case 3: TargetWeightStep()
                    case 4: PredictionStep()
                    case 5: ActivityStep()
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
            SBPrimaryButton(title: step == 5 ? "See My Plan" : "Continue") {
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    @State private var pulse = false

    private var ringOpacity: Double { colorScheme == .dark ? 0.12 : 0.18 }
    private var haloOpacity: Double { colorScheme == .dark ? 0.55 : 0.22 }
    private var haloRadius: CGFloat { colorScheme == .dark ? 32 : 18 }

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                // Thin pulsing rings (cleaner on both light and dark backgrounds
                // than filled blobs of accent color, which look smudgy on white).
                ForEach([0.85, 1.05, 1.25], id: \.self) { scale in
                    Circle()
                        .stroke(Color.sbAccent.opacity(ringOpacity), lineWidth: 1)
                        .frame(width: 180, height: 180)
                        .scaleEffect(pulse ? scale * 1.12 : scale)
                        .opacity(pulse ? 0 : 1)
                        .animation(
                            .easeOut(duration: 2.4).repeatForever(autoreverses: false)
                                .delay((scale - 0.85) * 0.6),
                            value: pulse
                        )
                }

                Image("PowerPumpLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.sbAccent.opacity(haloOpacity), radius: haloRadius, x: 0, y: 0)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.6), value: appeared)
            }
            .frame(height: 220)

            VStack(spacing: 14) {
                Text("POWERPUMP")
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

// MARK: - Step 3: Target Weight

private struct TargetWeightStep: View {
    @ObservedObject private var profile = UserProfile.shared

    // Range adapts around the user's current weight so the cursor isn't lost.
    private var range: ClosedRange<Double> {
        let lower = max(30, profile.weightKg - 25)
        let upper = min(250, profile.weightKg + 25)
        return lower...upper
    }

    private var deltaKg: Double { profile.targetWeightKg - profile.weightKg }
    private var percentChange: Int {
        guard profile.weightKg > 0 else { return 0 }
        return abs(Int(round(deltaKg / profile.weightKg * 100)))
    }

    // Difficulty assessment: easy when |%| ≤ 5, moderate ≤ 10, ambitious > 10.
    private var assessment: (emoji: String, title: String, body: String) {
        let absPct = abs(percentChange)
        let lose = deltaKg < 0
        if absPct == 0 {
            return ("⚖️", "Maintain your weight",
                    "Stay consistent with nutrition and training to keep your current shape.")
        } else if absPct <= 5 {
            if lose { return ("👌", "Easy goal — lose %d%% of your body weight",
                              "Small, sustainable changes will get you there without effort.") }
            return ("👌", "Easy goal — gain %d%% of your body weight",
                    "A small surplus and consistent training will make this happen.")
        } else if absPct <= 10 {
            if lose { return ("👍", "Moderate goal — lose %d%% of your body weight",
                              "Moderate weight loss can produce a significant improvement in mood and energy.") }
            return ("👍", "Moderate goal — gain %d%% of your body weight",
                    "A solid surplus with regular training will build noticeable muscle.")
        } else {
            if lose { return ("💪", "Ambitious goal — lose %d%% of your body weight",
                              "This will take dedication — patience and consistency are key.") }
            return ("💪", "Ambitious goal — gain %d%% of your body weight",
                    "This will take dedication — patience and consistency are key.")
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text("Your target weight")
                        .font(SBFont.display(28))
                        .foregroundColor(.sbTextPrimary)
                        .multilineTextAlignment(.center)
                    Text("Slide to set the weight you want to reach")
                        .font(SBFont.body())
                        .foregroundColor(.sbTextSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    // Big target + small current weight reference on the right
                    HStack(alignment: .lastTextBaseline, spacing: 16) {
                        Spacer()
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(String(format: "%.0f", profile.targetWeightKg))
                                .font(SBFont.display(56))
                                .foregroundColor(.sbTextPrimary)
                                .monospacedDigit()
                            Text("kg")
                                .font(SBFont.heading(18))
                                .foregroundColor(.sbTextSecondary)
                                .offset(y: 10)
                        }
                        if abs(profile.targetWeightKg - profile.weightKg) >= 0.5 {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 11, weight: .bold))
                                Text(String(format: "%.0f", profile.weightKg))
                                    .font(SBFont.heading(20))
                                    .monospacedDigit()
                            }
                            .foregroundColor(.sbTextSecondary.opacity(0.55))
                            .padding(.bottom, 8)
                        }
                        Spacer()
                    }

                    SBRulerPicker(
                        value: $profile.targetWeightKg,
                        range: range, step: 1, majorTickEvery: 10
                    )

                    deltaIndicator
                }
                .padding(16)
                .background(Color.sbSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))

                assessmentCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .onAppear {
            // First time we land here, default the target to the user's current
            // weight so the cursor starts in a sensible place.
            if profile.targetWeightKg == 75 && profile.weightKg != 75 {
                profile.targetWeightKg = profile.weightKg
            }
        }
    }

    // Visually shows "you are losing/gaining X kg" with a tinted track.
    private var deltaIndicator: some View {
        let absKg = abs(deltaKg)
        let lose = deltaKg < 0
        let label = absKg < 0.5
            ? String(localized: "Maintain")
            : (lose
                ? String(format: NSLocalizedString("Lose %.0f kg", comment: ""), absKg)
                : String(format: NSLocalizedString("Gain %.0f kg", comment: ""), absKg))
        let tint: Color = absKg < 0.5 ? .sbAccent : (lose ? .sbCyan : .sbGreen)

        return HStack {
            Circle().fill(tint).frame(width: 8, height: 8)
            Text(label)
                .font(SBFont.label())
                .foregroundColor(.sbTextPrimary)
            Spacer()
        }
    }

    private var assessmentCard: some View {
        let a = assessment
        let formattedTitle = String(format: NSLocalizedString(a.title, comment: ""), percentChange)
        let formattedBody  = NSLocalizedString(a.body, comment: "")

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(a.emoji).font(.system(size: 20))
                Text(formattedTitle)
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(formattedBody)
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sbSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
    }
}

// MARK: - Step 4: Prediction (when will you reach your target)

private struct PredictionStep: View {
    @ObservedObject private var profile = UserProfile.shared

    private var deltaKg: Double { profile.targetWeightKg - profile.weightKg }
    private var isLoss:  Bool   { deltaKg < 0 }
    private var isMaintenance: Bool { abs(deltaKg) < 0.5 }

    // Weekly rate, adaptive to BMI (people with more excess weight lose faster
    // — early water loss, more total body to mobilize from). Within a safe
    // range of 0.5–1.5 kg/week for loss, 0.35 kg/week for lean gain.
    private var weeklyChangeKg: Double {
        if isMaintenance { return 0 }
        if isLoss {
            let rate: Double
            switch profile.bmi {
            case 30...:    rate = 0.012   // Obese: ~1.2% per week
            case 25..<30:  rate = 0.010   // Overweight: ~1% per week
            case 18.5..<25: rate = 0.0085 // Normal: ~0.85% per week
            default:       rate = 0.006   // Underweight: ~0.6% per week
            }
            return min(1.5, max(0.5, profile.weightKg * rate))
        }
        return 0.35  // Lean bulking, sustainable pace
    }

    private var weeksToTarget: Int {
        guard weeklyChangeKg > 0 else { return 0 }
        return max(1, Int(ceil(abs(deltaKg) / weeklyChangeKg)))
    }

    private var targetDate: Date {
        Calendar.current.date(byAdding: .day, value: weeksToTarget * 7, to: .now) ?? .now
    }

    private var targetDateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: LanguageManager.shared.selectedCode)
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f.string(from: targetDate)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Title with date highlight
                VStack(spacing: 4) {
                    Text(isMaintenance ? "Your maintenance goal" : "We predict you'll be")
                        .font(SBFont.body())
                        .foregroundColor(.sbTextSecondary)
                        .multilineTextAlignment(.center)

                    if isMaintenance {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(String(format: "%.0f", profile.weightKg))
                                .font(SBFont.display(40))
                                .foregroundColor(.sbTextPrimary)
                            Text("kg")
                                .font(SBFont.heading(20))
                                .foregroundColor(.sbTextSecondary)
                        }
                    } else {
                        VStack(spacing: 6) {
                            HStack(alignment: .lastTextBaseline, spacing: 6) {
                                Text(String(format: "%.0f", profile.targetWeightKg))
                                    .font(SBFont.display(40))
                                    .foregroundColor(.sbTextPrimary)
                                Text("kg")
                                    .font(SBFont.heading(20))
                                    .foregroundColor(.sbTextSecondary)
                                Text("on")
                                    .font(SBFont.heading(20))
                                    .foregroundColor(.sbTextSecondary)
                                Text(targetDateString)
                                    .font(SBFont.display(38))
                                    .foregroundColor(.sbAccent)
                            }
                            paceBadge
                        }
                    }
                }
                .padding(.horizontal, 16)

                if isMaintenance {
                    maintenanceCard
                } else {
                    chartCard
                }

                VStack(spacing: 6) {
                    Text("Excellent!")
                        .font(SBFont.heading(20))
                        .foregroundColor(.sbTextPrimary)
                    Text("We have a clear understanding of you and your body")
                        .font(SBFont.body())
                        .foregroundColor(.sbTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 8)
        }
    }

    // Small badge: weekly pace and total duration, so the prediction is transparent.
    private var paceBadge: some View {
        let weeks = weeksToTarget
        let months = weeks / 4
        let extraWeeks = weeks % 4
        let durationText: String = {
            if weeks < 4 { return String(format: NSLocalizedString("%d weeks", comment: ""), weeks) }
            if extraWeeks == 0 { return String(format: NSLocalizedString("%d months", comment: ""), months) }
            return String(format: NSLocalizedString("%d months, %d weeks", comment: ""), months, extraWeeks)
        }()
        let rateText = String(format: NSLocalizedString("%.1f kg/week", comment: ""), weeklyChangeKg)
        return HStack(spacing: 6) {
            Image(systemName: "speedometer")
                .font(.system(size: 11, weight: .semibold))
            Text("\(rateText) · \(durationText)")
                .font(SBFont.caption())
        }
        .foregroundColor(.sbTextSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.sbSurfaceRaised)
        .cornerRadius(20)
    }

    // MARK: - Chart card

    private var chartCard: some View {
        VStack(spacing: 8) {
            ZStack {
                // Curve: smooth S-shape from current weight to target weight.
                PredictionCurveShape(progress: 1.0, downward: isLoss)
                    .stroke(
                        LinearGradient(
                            colors: [.orange.opacity(0.9), .sbAccent],
                            startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(height: 220)
                    .overlay(
                        PredictionCurveShape(progress: 1.0, downward: isLoss, fill: true)
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.18), .clear],
                                    startPoint: .top, endPoint: .bottom)
                            )
                    )

                GeometryReader { geo in
                    // Start dot (Today)
                    Circle()
                        .fill(.orange)
                        .frame(width: 12, height: 12)
                        .position(
                            x: 12,
                            y: isLoss ? 16 : geo.size.height - 16
                        )

                    // Vertical dashed line at Today
                    Path { path in
                        path.move(to: CGPoint(x: 12, y: isLoss ? 16 : geo.size.height - 16))
                        path.addLine(to: CGPoint(x: 12, y: geo.size.height))
                    }
                    .stroke(Color.orange.opacity(0.4),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    // End dot (target)
                    Circle()
                        .fill(Color.sbAccent)
                        .frame(width: 12, height: 12)
                        .position(
                            x: geo.size.width - 12,
                            y: isLoss ? geo.size.height - 16 : 16
                        )

                    // Vertical dashed line at target
                    Path { path in
                        path.move(to: CGPoint(x: geo.size.width - 12,
                                              y: isLoss ? geo.size.height - 16 : 16))
                        path.addLine(to: CGPoint(x: geo.size.width - 12, y: geo.size.height))
                    }
                    .stroke(Color.sbAccent.opacity(0.4),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    // Trophy bubble above the target dot
                    VStack(spacing: 2) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [.orange, .yellow],
                                                     startPoint: .top, endPoint: .bottom))
                                .frame(width: 42, height: 42)
                                .shadow(color: .orange.opacity(0.4), radius: 8)
                            Text("🏆").font(.system(size: 24))
                        }
                        Triangle()
                            .fill(.orange)
                            .frame(width: 8, height: 6)
                    }
                    .position(
                        x: geo.size.width - 12,
                        y: isLoss ? geo.size.height - 50 : 50
                    )
                }
            }
            .frame(height: 220)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                    Text(String(format: "%.0f kg", profile.weightKg))
                        .font(SBFont.label(10))
                        .foregroundColor(.sbTextSecondary.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(targetDateString)
                        .font(SBFont.caption())
                        .fontWeight(.semibold)
                        .foregroundColor(.sbAccent)
                    Text(String(format: "%.0f kg", profile.targetWeightKg))
                        .font(SBFont.label(10))
                        .foregroundColor(.sbAccent.opacity(0.7))
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(Color.sbSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.sbBorder))
        .padding(.horizontal, 20)
    }

    private var maintenanceCard: some View {
        VStack(spacing: 14) {
            Text("⚖️").font(.system(size: 56))
            Text("Maintenance mode")
                .font(SBFont.heading(16))
                .foregroundColor(.sbTextPrimary)
            Text("Your plan will help you stay at your current weight while building healthy habits.")
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .background(Color.sbSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.sbBorder))
        .padding(.horizontal, 20)
    }
}

// Smooth S-curve from one corner to the diagonally opposite one.
// Used both as a stroked line and (with fill=true) as an area underneath.
private struct PredictionCurveShape: Shape {
    var progress: CGFloat = 1.0
    var downward: Bool
    var fill: Bool = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startY = downward ? 16 : rect.height - 16
        let endY   = downward ? rect.height - 16 : 16
        let start  = CGPoint(x: 12, y: startY)
        let end    = CGPoint(x: rect.width - 12, y: endY)

        let cp1 = CGPoint(x: rect.width * 0.45, y: startY)
        let cp2 = CGPoint(x: rect.width * 0.55, y: endY)

        path.move(to: start)
        path.addCurve(to: end, control1: cp1, control2: cp2)

        if fill {
            path.addLine(to: CGPoint(x: rect.width - 12, y: rect.height))
            path.addLine(to: CGPoint(x: 12, y: rect.height))
            path.closeSubpath()
        }
        return path
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

                // Sex — drives the BMR formula (Mifflin-St Jeor differs by sex)
                VStack(alignment: .leading, spacing: 6) {
                    Label("Sex", systemImage: "person.2")
                        .font(SBFont.label())
                        .foregroundColor(.sbTextSecondary)
                    HStack(spacing: 0) {
                        ForEach(BiologicalSex.allCases, id: \.self) { option in
                            let selected = profile.sex == option
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { profile.sex = option }
                                HapticManager.selection()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: option.icon)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(LocalizedStringKey(option.rawValue))
                                        .font(SBFont.body())
                                }
                                .foregroundColor(selected ? .white : .sbTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selected ? Color.sbAccent : Color.clear)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(Color.sbSurface)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
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
