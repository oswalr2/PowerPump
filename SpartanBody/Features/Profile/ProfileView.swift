import SwiftUI

struct ProfileView: View {
    @ObservedObject private var profile  = UserProfile.shared
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
                Circle()
                    .stroke(LinearGradient.sbAccentGradient, lineWidth: 3)
                    .frame(width: 98, height: 98)
                Circle().fill(Color.sbAccentDim).frame(width: 86, height: 86)
                Text(profile.name.isEmpty ? "?" : String(profile.name.prefix(1)).uppercased())
                    .font(SBFont.display(36))
                    .foregroundColor(.sbAccent)
            }
            .shadow(color: Color.sbAccent.opacity(0.25), radius: 10)
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
