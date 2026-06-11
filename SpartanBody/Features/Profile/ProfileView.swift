import SwiftUI

struct ProfileView: View {
    @ObservedObject private var profile  = UserProfile.shared
    @ObservedObject private var notif    = NotificationManager.shared
    @ObservedObject private var language = LanguageManager.shared
    @ObservedObject private var health   = HealthKitService.shared
    @State private var showSettings      = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        avatarSection
                        statsCard
                        targetsCard
                        healthCard
                        notificationsCard
                        settingsButton
                        SBSecondaryButton(title: "Edit Profile") {
                            profile.onboardingDone = false
                        }
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear { notif.checkStatus() }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    // MARK: - Settings button

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.sbAccent)
                    .font(.system(size: 16))
                Text("Settings")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Text(language.currentLanguage.flag)
                    .font(.system(size: 16))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sbTextSecondary.opacity(0.5))
            }
            .padding(16)
            .background(Color.sbSurface)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.sbAccentDim).frame(width: 90, height: 90)
                Text(profile.name.isEmpty ? "?" : String(profile.name.prefix(1)).uppercased())
                    .font(SBFont.display(36))
                    .foregroundColor(.sbAccent)
            }
            Text(profile.name.isEmpty ? "Spartan" : profile.name)
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)
            SBTag(text: profile.goal.rawValue)
        }
        .padding(.top, 16)
    }

    // MARK: - Stats

    private var statsCard: some View {
        SBCard {
            VStack(spacing: 16) {
                Text("Your Stats")
                    .font(SBFont.heading())
                    .foregroundColor(.sbTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    SBStatBox(value: "\(Int(profile.weightKg))", label: "Weight", unit: "kg").frame(maxWidth: .infinity)
                    Divider().frame(height: 40)
                    SBStatBox(value: "\(Int(profile.heightCm))", label: "Height", unit: "cm").frame(maxWidth: .infinity)
                    Divider().frame(height: 40)
                    SBStatBox(value: String(format: "%.1f", profile.bmi), label: "BMI", unit: "").frame(maxWidth: .infinity)
                }

                HStack {
                    Text("BMI Category").font(SBFont.body()).foregroundColor(.sbTextSecondary)
                    Spacer()
                    SBTag(text: profile.bmiCategory,
                          color: profile.bmi < 18.5 || profile.bmi >= 25 ? .sbRed : .sbGreen)
                }
            }
        }
    }

    // MARK: - Targets

    private var targetsCard: some View {
        SBCard {
            VStack(spacing: 12) {
                Text("Daily Targets")
                    .font(SBFont.heading())
                    .foregroundColor(.sbTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TargetRow(label: "Calories", value: "\(profile.dailyCalorieTarget) kcal")
                TargetRow(label: "Protein",  value: "\(profile.dailyProteinTarget) g")
                TargetRow(label: "Activity", value: profile.activityLevel.rawValue)
            }
        }
    }

    // MARK: - Notifications

    private var notificationsCard: some View {
        SBCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "bell.fill").foregroundColor(.sbAccent)
                    Text("Notifications")
                        .font(SBFont.heading())
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                    if notif.isAuthorized {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.sbGreen)
                    }
                }

                if !notif.isAuthorized {
                    // Permission prompt
                    VStack(spacing: 10) {
                        Text("Allow notifications to get reminders for workouts, hydration, and meals.")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                            .lineSpacing(3)

                        SBPrimaryButton(title: "Enable Notifications") {
                            notif.requestPermission()
                        }
                    }
                } else {
                    // Workout reminder
                    NotifRow(
                        icon: "dumbbell.fill",
                        title: "Workout Reminder",
                        isOn: $notif.workoutEnabled
                    ) {
                        if notif.workoutEnabled {
                            DatePicker("", selection: $notif.workoutTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(.sbAccent)
                        }
                    }

                    Divider().background(Color.sbBorder)

                    // Hydration reminder
                    NotifRow(
                        icon: "drop.fill",
                        title: "Hydration Reminder",
                        isOn: $notif.hydrationEnabled
                    ) {
                        if notif.hydrationEnabled {
                            HStack(spacing: 0) {
                                Text("Every")
                                    .font(SBFont.caption())
                                    .foregroundColor(.sbTextSecondary)
                                Spacer()
                                ForEach([1, 2, 3], id: \.self) { h in
                                    Button {
                                        notif.hydrationEveryHours = h
                                    } label: {
                                        Text("\(h)h")
                                            .font(SBFont.caption())
                                            .foregroundColor(notif.hydrationEveryHours == h ? .white : .sbTextSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(notif.hydrationEveryHours == h ? Color.sbAccent : Color.sbSurfaceRaised)
                                            .cornerRadius(7)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Divider().background(Color.sbBorder)

                    // Meal reminders
                    NotifRow(
                        icon: "fork.knife",
                        title: "Meal Reminders",
                        isOn: $notif.mealsEnabled
                    ) {
                        if notif.mealsEnabled {
                            VStack(spacing: 8) {
                                MealTimeRow(label: "Breakfast", time: $notif.breakfastTime)
                                MealTimeRow(label: "Lunch",     time: $notif.lunchTime)
                                MealTimeRow(label: "Dinner",    time: $notif.dinnerTime)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Health

    private var healthCard: some View {
        SBCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "heart.fill").foregroundColor(.sbRed)
                    Text("Apple Health")
                        .font(SBFont.heading())
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                    if health.isAuthorized {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.sbGreen)
                    }
                }

                if !health.isAvailable {
                    Text("Apple Health is not available on this device.")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                } else if health.isAuthorized {
                    HStack(spacing: 0) {
                        healthStat("\(health.stepsToday)", "Steps", "figure.walk")
                            .frame(maxWidth: .infinity)
                        Divider().frame(height: 36)
                        healthStat("\(Int(health.activeEnergyToday))", "Active kcal", "flame.fill")
                            .frame(maxWidth: .infinity)
                    }
                    Text("Workouts, meals, and water sync automatically.")
                        .font(SBFont.label(11))
                        .foregroundColor(Color.sbTextSecondary.opacity(0.6))
                } else {
                    Text("Connect Apple Health to sync workouts, nutrition, and activity data.")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                        .lineSpacing(3)
                    SBPrimaryButton(title: "Connect Apple Health") {
                        health.requestAuthorization()
                    }
                }
            }
        }
    }

    private func healthStat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.sbRed)
            Text(value)
                .font(SBFont.heading(18))
                .foregroundColor(.sbTextPrimary)
                .monospacedDigit()
            Text(label)
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
        }
        .padding(.vertical, 6)
    }

}

// MARK: - Notification sub-views

private struct NotifRow<Extra: View>: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    @ViewBuilder let extra: () -> Extra

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.sbAccent)
                    .frame(width: 20)
                Text(title)
                    .font(SBFont.body())
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.sbAccent)
            }
            extra()
        }
    }
}

private struct MealTimeRow: View {
    let label: String
    @Binding var time: Date

    var body: some View {
        HStack {
            Text(label)
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .frame(width: 70, alignment: .leading)
            Spacer()
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(.sbAccent)
        }
    }
}

// MARK: - TargetRow

private struct TargetRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(LocalizedStringKey(label)).font(SBFont.body()).foregroundColor(.sbTextSecondary)
            Spacer()
            Text(LocalizedStringKey(value)).font(SBFont.body()).fontWeight(.semibold).foregroundColor(.sbTextPrimary)
        }
        .padding(.vertical, 2)
    }
}
