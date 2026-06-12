import SwiftUI

struct SettingsView: View {
    @ObservedObject private var theme    = ThemeManager.shared
    @ObservedObject private var language = LanguageManager.shared
    @ObservedObject private var notif    = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showAbout    = false
    @State private var showLanguage = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                List {
                    // MARK: Appearance
                    Section {
                        appearanceRow
                    } header: {
                        sectionHeader("Appearance")
                    }

                    // MARK: Language
                    Section {
                        languageRow
                    } header: {
                        sectionHeader("Language")
                    }

                    // MARK: Notifications
                    Section {
                        if !notif.isAuthorized {
                            notificationsPermissionRow
                        } else {
                            workoutReminderRow
                            hydrationReminderRow
                            mealsReminderRow
                            sleepReminderRow
                        }
                    } header: {
                        sectionHeader("Notifications")
                    }

                    // MARK: Support
                    Section {
                        supportRow
                        aboutRow
                    } header: {
                        sectionHeader("Support")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.sbTextSecondary)
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .onAppear { notif.checkStatus() }
        .sheet(isPresented: $showAbout) { AboutView() }
        .confirmationDialog("", isPresented: $showLanguage, titleVisibility: .hidden) {
            ForEach(LanguageManager.available) { lang in
                Button(lang.flag + " " + lang.nativeName) {
                    language.select(lang.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Appearance row

    private var appearanceRow: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Theme", systemImage: "circle.lefthalf.filled")
                    .foregroundColor(.sbTextPrimary)
                Spacer()
            }
            HStack(spacing: 0) {
                ForEach(AppTheme.allCases, id: \.self) { t in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { theme.current = t }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: t == .dark ? "moon.fill" : "sun.max.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text(LocalizedStringKey(t.rawValue))
                                .font(SBFont.caption())
                        }
                        .foregroundColor(theme.current == t ? .white : .sbTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(theme.current == t ? Color.sbAccent : Color.clear)
                        .cornerRadius(9)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.sbSurfaceRaised)
            .cornerRadius(12)
        }
        .padding(.vertical, 6)
        .listRowBackground(Color.sbSurface)
    }

    // MARK: - Language row

    private var languageRow: some View {
        Button {
            showLanguage = true
        } label: {
            HStack {
                Label("Language", systemImage: "globe")
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Text(language.currentLanguage.flag + " " + language.currentLanguage.nativeName)
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sbTextSecondary.opacity(0.5))
            }
        }
        .listRowBackground(Color.sbSurface)
    }

    // MARK: - Notification rows

    private var notificationsPermissionRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Allow notifications to get reminders for workouts, hydration, and meals.")
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .lineSpacing(3)

            SBPrimaryButton(title: "Enable Notifications") {
                notif.requestPermission()
            }
        }
        .padding(.vertical, 6)
        .listRowBackground(Color.sbSurface)
    }

    private var workoutReminderRow: some View {
        NotifRow(icon: "dumbbell.fill", title: "Workout Reminder", isOn: $notif.workoutEnabled) {
            if notif.workoutEnabled {
                DatePicker("", selection: $notif.workoutTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(.sbAccent)
            }
        }
        .listRowBackground(Color.sbSurface)
    }

    private var hydrationReminderRow: some View {
        NotifRow(icon: "drop.fill", title: "Hydration Reminder", isOn: $notif.hydrationEnabled) {
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
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .listRowBackground(Color.sbSurface)
    }

    private var mealsReminderRow: some View {
        NotifRow(icon: "fork.knife", title: "Meal Reminders", isOn: $notif.mealsEnabled) {
            if notif.mealsEnabled {
                VStack(spacing: 8) {
                    MealTimeRow(label: "Breakfast", time: $notif.breakfastTime)
                    MealTimeRow(label: "Lunch",     time: $notif.lunchTime)
                    MealTimeRow(label: "Dinner",    time: $notif.dinnerTime)
                }
            }
        }
        .listRowBackground(Color.sbSurface)
    }

    private var sleepReminderRow: some View {
        NotifRow(icon: "moon.zzz.fill", title: "Sleep Reminder", isOn: $notif.sleepEnabled) {
            if notif.sleepEnabled {
                DatePicker("", selection: $notif.sleepTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(.sbAccent)
            }
        }
        .listRowBackground(Color.sbSurface)
    }

    // MARK: - Support rows

    private var supportRow: some View {
        Button {
            let email = Config.supportEmail
            if let url = URL(string: "mailto:\(email)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Label("Contact Support", systemImage: "envelope.fill")
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sbTextSecondary.opacity(0.5))
            }
        }
        .listRowBackground(Color.sbSurface)
    }

    private var aboutRow: some View {
        Button {
            showAbout = true
        } label: {
            HStack {
                Label("About & Privacy", systemImage: "info.circle.fill")
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sbTextSecondary.opacity(0.5))
            }
        }
        .listRowBackground(Color.sbSurface)
    }

    // MARK: - Helpers

    private func sectionHeader(_ key: String) -> some View {
        Text(LocalizedStringKey(key))
            .font(SBFont.label(12))
            .foregroundColor(.sbTextSecondary)
            .textCase(nil)
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
                Text(LocalizedStringKey(title))
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
            Text(LocalizedStringKey(label))
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
