import SwiftUI

struct DashboardView: View {
    @ObservedObject private var profile    = UserProfile.shared
    @ObservedObject private var foodLog    = FoodLogStore.shared
    @ObservedObject private var water      = WaterStore.shared
    @ObservedObject private var workouts   = WorkoutStore.shared
    @ObservedObject private var challenges = ChallengeStore.shared
    @ObservedObject private var health     = HealthKitService.shared
    @State private var showCoach        = false
    @State private var showNutrition    = false
    @State private var showChallenges   = false
    @State private var showFoodScanner  = false
    @State private var showBarcodeScanner = false
    @State private var showSettings     = false
    @State private var appeared         = false

    private var caloriesConsumed: Int { Int(foodLog.todayCalories) }
    private var caloriesBurned: Int {
        health.isAuthorized && health.activeEnergyToday > 0
            ? Int(health.activeEnergyToday)
            : workouts.todayCaloriesBurned
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return NSLocalizedString("Good morning,", comment: "")
        case 12..<17: return NSLocalizedString("Good afternoon,", comment: "")
        default:      return NSLocalizedString("Good evening,", comment: "")
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                            .slideIn(appeared, delay: 0.0)
                        calorieRingSection
                            .slideIn(appeared, delay: 0.08)
                        macroSection
                            .slideIn(appeared, delay: 0.14)
                        waterSection
                            .slideIn(appeared, delay: 0.20)
                        quickActionsSection
                            .slideIn(appeared, delay: 0.26)
                        challengeCard
                            .slideIn(appeared, delay: 0.32)
                        aiCoachCard
                            .slideIn(appeared, delay: 0.38)
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            if health.isAuthorized { health.fetchTodayStats() }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                Text(profile.name.isEmpty ? "Spartan" : profile.name)
                    .font(SBFont.display(28))
                    .foregroundColor(.sbTextPrimary)
            }
            Spacer()

            if health.isAuthorized && health.stepsToday > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.sbAccent)
                    Text("\(health.stepsToday)")
                        .font(SBFont.caption())
                        .fontWeight(.bold)
                        .foregroundColor(.sbTextPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.sbAccentDim)
                .cornerRadius(10)
            }

            if workouts.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.orange)
                    Text("\(workouts.currentStreak)")
                        .font(SBFont.caption())
                        .fontWeight(.bold)
                        .foregroundColor(.sbTextPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(10)
            }

            Button {
                HapticManager.light()
                showSettings = true
            } label: {
                ZStack {
                    Circle().fill(Color.sbSurface).frame(width: 46, height: 46)
                    Image(systemName: "bell.fill")
                        .foregroundColor(.sbAccent)
                        .font(.system(size: 18))
                }
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    // MARK: - Calorie Ring
    private var calorieRingSection: some View {
        SBCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Today's Calories")
                        .font(SBFont.heading())
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                    SBTag(text: profile.goal.rawValue)
                }

                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.sbSurfaceRaised, lineWidth: 16)
                        .frame(width: 170, height: 170)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: min(Double(caloriesConsumed) / Double(profile.dailyCalorieTarget), 1.0))
                        .stroke(
                            caloriesConsumed > profile.dailyCalorieTarget
                                ? AnyShapeStyle(Color.sbRed)
                                : AnyShapeStyle(AngularGradient(
                                    colors: [.sbAccent, .sbCyan, .sbAccent],
                                    center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 170, height: 170)
                        .shadow(color: Color.sbAccent.opacity(caloriesConsumed > 0 ? 0.35 : 0), radius: 8)
                        .animation(.spring(), value: caloriesConsumed)

                    VStack(spacing: 2) {
                        Text("\(caloriesConsumed)")
                            .font(SBFont.display(38))
                            .foregroundColor(.sbTextPrimary)
                            .monospacedDigit()
                        Text("/ \(profile.dailyCalorieTarget) kcal")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    }
                }
                .padding(.vertical, 6)

                HStack(spacing: 0) {
                    SBStatBox(value: "\(profile.dailyCalorieTarget - caloriesConsumed)",
                              label: "Remaining", unit: "kcal")
                        .frame(maxWidth: .infinity)

                    Divider().frame(height: 40).background(Color.sbBorder)

                    SBStatBox(value: "\(caloriesConsumed)",
                              label: "Consumed", unit: "kcal", accent: .sbGreen)
                        .frame(maxWidth: .infinity)

                    Divider().frame(height: 40).background(Color.sbBorder)

                    SBStatBox(value: "\(caloriesBurned)",
                              label: "Burned", unit: "kcal", accent: .sbRed)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Macros
    private var macroSection: some View {
        SBCard {
            VStack(spacing: 14) {
                HStack {
                    Text("Macros")
                        .font(SBFont.heading())
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                    Text("Today")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }

                MacroRow(name: "Protein", current: Int(foodLog.todayProtein), target: profile.dailyProteinTarget,
                         unit: "g", color: .sbAccent)
                MacroRow(name: "Carbs",   current: Int(foodLog.todayCarbs), target: Int(Double(profile.dailyCalorieTarget) * 0.45 / 4),
                         unit: "g", color: .sbGreen)
                MacroRow(name: "Fat",     current: Int(foodLog.todayFat), target: Int(Double(profile.dailyCalorieTarget) * 0.25 / 9),
                         unit: "g", color: Color.orange)
            }
        }
    }

    // MARK: - Water
    private var waterSection: some View {
        SBCard {
            VStack(spacing: 14) {
                HStack {
                    Text("Water Intake")
                        .font(SBFont.heading())
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                    Text("\(water.todayGlasses) / 8 glasses")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }

                HStack(spacing: 8) {
                    ForEach(0..<8) { i in
                        Button {
                            let newValue = i < water.todayGlasses ? i : i + 1
                            water.set(newValue)
                            HapticManager.light()
                        } label: {
                            Image(systemName: i < water.todayGlasses ? "drop.fill" : "drop")
                                .foregroundColor(i < water.todayGlasses ? .sbCyan : Color.sbTextSecondary.opacity(0.35))
                                .font(.system(size: 22))
                                .scaleEffect(i < water.todayGlasses ? 1.1 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: water.todayGlasses)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - Challenge card

    private var challengeCard: some View {
        Button { showChallenges = true } label: {
            if let active = challenges.active.first, let def = active.definition {
                // Show active challenge progress
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(def.color.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: def.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(def.color)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(def.name)
                                .font(SBFont.heading(15))
                                .foregroundColor(.sbTextPrimary)
                            if challenges.active.count > 1 {
                                Text("+\(challenges.active.count - 1)")
                                    .font(SBFont.label(10))
                                    .foregroundColor(.sbTextSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.sbSurfaceRaised)
                                    .cornerRadius(6)
                            }
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.sbBorder).frame(height: 5)
                                RoundedRectangle(cornerRadius: 3).fill(def.color)
                                    .frame(width: geo.size.width * active.progress, height: 5)
                            }
                        }
                        .frame(height: 5)
                        Text("\(active.completedDayKeys.count)/\(active.totalDays) days · \(active.isDayComplete(.now) ? "Done today ✓" : "Pending today")")
                            .font(SBFont.label(11))
                            .foregroundColor(active.isDayComplete(.now) ? def.color : .sbTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.sbAccent)
                }
                .padding(14)
                .background(Color.sbSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(def.color.opacity(0.35), lineWidth: 1.5))
            } else {
                // No active challenge — invite to start
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 50, height: 50)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Start a Challenge")
                            .font(SBFont.heading(15))
                            .foregroundColor(.sbTextPrimary)
                        Text("Build consistency with 7–30 day goals")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.sbAccent)
                }
                .padding(14)
                .background(Color.sbSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.35), lineWidth: 1.5))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Coach card

    private var aiCoachCard: some View {
        Button { showCoach = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.sbAccent.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.sbAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Coach")
                        .font(SBFont.heading(16))
                        .foregroundColor(.sbTextPrimary)
                    Text("Get your personalised free 7-day plan")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.sbAccent)
            }
            .padding(16)
            .background(Color.sbSurface)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.sbAccent.opacity(0.4), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showCoach) { AICoachView() }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)

            HStack(spacing: 10) {
                QuickActionButton(icon: "camera.fill",       label: "Scan Food") {
                    HapticManager.light()
                    showFoodScanner = true
                }
                QuickActionButton(icon: "barcode.viewfinder", label: "Scan Barcode") {
                    HapticManager.light()
                    showBarcodeScanner = true
                }
                QuickActionButton(icon: "play.fill",         label: "Start Workout") {
                    HapticManager.medium()
                    NotificationCenter.default.post(name: .switchToTab, object: 1)
                }
                QuickActionButton(icon: "fork.knife",        label: "Log Meal") {
                    HapticManager.light()
                    showNutrition = true
                }
            }
        }
        .sheet(isPresented: $showNutrition)       { NutritionView() }
        .sheet(isPresented: $showChallenges)      { ChallengesView() }
        .sheet(isPresented: $showFoodScanner)     { FoodScannerView() }
        .sheet(isPresented: $showBarcodeScanner)  {
            BarcodeScanSheet { item in
                FoodLogStore.shared.add(item, grams: 100, meal: .snack)
                HapticManager.success()
            }
        }
    }
}

private struct MacroRow: View {
    let name: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color

    private var progress: Double {
        target > 0 ? Double(current) / Double(target) : 0
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(LocalizedStringKey(name))
                    .font(SBFont.body())
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Text("\(current) / \(target) \(unit)")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                    .monospacedDigit()
            }
            SBProgressBar(progress: progress, color: color)
        }
    }
}

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.sbAccent.opacity(0.15))
                        .frame(height: 52)
                    Image(systemName: icon)
                        .foregroundColor(.sbAccent)
                        .font(.system(size: 20, weight: .semibold))
                }
                Text(LocalizedStringKey(label))
                    .font(SBFont.label(10))
                    .foregroundColor(.sbTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
