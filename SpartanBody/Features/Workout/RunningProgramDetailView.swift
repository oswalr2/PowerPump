import SwiftUI

struct RunningProgramDetailView: View {
    let program: RunningProgram
    @ObservedObject private var progress = RunProgramStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: Tab = .intro
    @State private var presentedSession: ProgramSessionRequest?

    enum Tab { case intro, progress }

    var body: some View {
        ZStack {
            Color.sbBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    tabSelector
                    Group {
                        if selectedTab == .intro { introContent } else { progressContent }
                    }
                    .padding(.horizontal, 20)
                    Spacer(minLength: 120)
                }
            }
            VStack { Spacer(); startButton }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(verbatim: PT(program.nameKey))
                    .font(SBFont.heading(14))
                    .foregroundColor(.sbTextPrimary)
                    .textCase(.uppercase)
            }
        }
        .fullScreenCover(item: $presentedSession) { req in
            ProgramSessionView(program: program,
                               weekNumber: req.weekNumber,
                               day: req.day)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Rectangle().fill(Color.sbAccent).frame(width: 4, height: 16)
                Text(String(format: NSLocalizedString("%lld-week program", comment: ""), program.totalWeeks))
                    .font(SBFont.label(11))
                    .foregroundColor(.sbTextPrimary)
                    .textCase(.uppercase)
            }
            Text(verbatim: PT(program.nameKey))
                .font(SBFont.display(28))
                .foregroundColor(.sbTextPrimary)
            HStack(spacing: 24) {
                LevelDots(label: "Endurance", level: program.endurance)
                LevelDots(label: "Speed",     level: program.speed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 18)
    }

    // MARK: - Tab selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach([Tab.intro, Tab.progress], id: \.self) { t in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = t }
                } label: {
                    VStack(spacing: 8) {
                        Text(LocalizedStringKey(t == .intro ? "Introduction" : "Progress"))
                            .font(SBFont.heading(16))
                            .foregroundColor(selectedTab == t ? .sbTextPrimary : .sbTextSecondary)
                        Rectangle()
                            .fill(selectedTab == t ? Color.sbAccent : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Intro tab

    private var introContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            sectionTitle("About the programs")
            aboutCard
            badgesGrid
            sectionTitle("Expected results")
            goalsCard
            sectionTitle("Your personalised plan")
            phasesTimeline
        }
        .padding(.top, 4)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            aboutRow(icon: "figure.run",
                     title: "Scientific hybrid",
                     subtitle: "Walking · Jogging · Running")
            aboutRow(icon: "checkmark.circle",
                     title: program.durationRangeText,
                     subtitle: nil)
            aboutRow(icon: "calendar.badge.clock",
                     title: String(format: NSLocalizedString("%lld days/week", comment: ""), program.daysPerWeek),
                     subtitle: nil)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sbSurface)
        .cornerRadius(16)
    }

    private func aboutRow(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.sbAccent)
                .font(.system(size: 18))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SBFont.body())
                    .foregroundColor(.sbTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }
            }
            Spacer()
        }
    }

    private func aboutRow(icon: String, title: String, subtitle: String?) -> some View {
        aboutRow(icon: icon,
                 title: LocalizedStringKey(title),
                 subtitle: subtitle.map { LocalizedStringKey($0) })
    }

    private var badgesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(program.badgeKeys, id: \.self) { key in
                Text(verbatim: PT(key))
                    .font(SBFont.label(11))
                    .fontWeight(.semibold)
                    .foregroundColor(.sbTextPrimary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.sbSurfaceRaised)
                    .cornerRadius(20)
            }
        }
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(program.goalKeys, id: \.self) { key in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.sbAccent)
                        .font(.system(size: 18))
                    Text(verbatim: PT(key))
                        .font(SBFont.body())
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sbSurface)
        .cornerRadius(16)
    }

    private var phasesTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(program.phases.enumerated()), id: \.element.id) { idx, phase in
                phaseRow(phase: phase, isLast: idx == program.phases.count - 1)
            }
        }
        .padding(16)
        .background(Color.sbSurface)
        .cornerRadius(16)
    }

    private func phaseRow(phase: ProgramPhase, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle().stroke(Color.sbTextSecondary, lineWidth: 1.5).frame(width: 14, height: 14)
                if !isLast {
                    Rectangle()
                        .fill(Color.sbBorder)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: phase.icon).foregroundColor(.sbAccent)
                    Text(String(format: NSLocalizedString("Weeks %lld-%lld", comment: ""),
                                phase.weekStart, phase.weekEnd))
                        .font(SBFont.heading(15))
                        .foregroundColor(.sbTextPrimary)
                }
                Text(verbatim: PT(phase.titleKey))
                    .font(SBFont.heading(18))
                    .foregroundColor(.sbTextPrimary)
                Text(verbatim: PT(phase.bodyKey))
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                    .lineSpacing(3)
                if !isLast { Divider().padding(.top, 6) }
            }
            .padding(.bottom, isLast ? 0 : 14)
        }
    }

    // MARK: - Progress tab

    private var progressContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(program.weeks) { week in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.sbAccent)
                        Text(String(format: NSLocalizedString("Week %lld", comment: ""), week.weekNumber))
                            .font(SBFont.heading(18))
                            .foregroundColor(.sbTextPrimary)
                    }
                    ForEach(week.days) { day in
                        dayRow(week: week.weekNumber, day: day)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private func dayRow(week: Int, day: ProgramDay) -> some View {
        let globalDay = progress.globalDay(in: program, weekNumber: week, dayNumber: day.dayNumber)
        let unlocked = progress.isUnlocked(globalDay, in: program)
        let completed = progress.isCompleted(globalDay, in: program)

        return Button {
            guard unlocked else { return }
            presentedSession = ProgramSessionRequest(weekNumber: week, day: day)
        } label: {
            HStack(spacing: 14) {
                VStack(spacing: 0) {
                    Text(LocalizedStringKey("Day"))
                        .font(SBFont.label(10))
                        .foregroundColor(.sbTextSecondary)
                        .textCase(.uppercase)
                    Text("\(day.dayNumber)")
                        .font(SBFont.display(28))
                        .foregroundColor(unlocked ? .sbTextPrimary : .sbTextSecondary.opacity(0.6))
                }
                .frame(width: 56)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "stopwatch")
                        Text(day.formattedDuration)
                            .font(SBFont.heading(18))
                    }
                    .foregroundColor(unlocked ? .sbTextPrimary : .sbTextSecondary.opacity(0.6))

                    Rectangle()
                        .fill(unlocked ? Color.sbBorder : Color.sbSurfaceRaised)
                        .frame(height: 4)
                        .cornerRadius(2)

                    if completed {
                        actionPill(text: "Completed", color: .sbGreen, icon: "checkmark.circle.fill")
                    } else if unlocked {
                        actionPill(text: "Start", color: .sbAccent, icon: "play.fill")
                    }
                }

                Spacer()
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.sbTextSecondary)
                        .font(.system(size: 18))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.sbSurface)
            .cornerRadius(14)
            .opacity(unlocked ? 1 : 0.65)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    private func actionPill(text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold))
            Text(verbatim: PT(text))
                .font(SBFont.heading(14))
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(20)
    }

    // MARK: - Start button (sticky bottom)

    private var startButton: some View {
        Button {
            let next = nextSessionRequest()
            HapticManager.medium()
            presentedSession = next
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text(LocalizedStringKey("Start Now"))
                    .fontWeight(.bold)
            }
            .font(SBFont.heading(18))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.sbAccent, .sbAccent.opacity(0.7)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(20)
            .shadow(color: Color.sbAccent.opacity(0.35), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(verbatim: PT(key))
            .font(SBFont.heading(18))
            .foregroundColor(.sbTextPrimary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func nextSessionRequest() -> ProgramSessionRequest {
        let nextGlobal = progress.nextUnlockedDay(in: program)
        let perWeek = program.daysPerWeek
        let weekIdx = max(0, (nextGlobal - 1) / perWeek)
        let dayIdx  = max(0, (nextGlobal - 1) % perWeek)
        let safeWeek = min(weekIdx, program.weeks.count - 1)
        let week = program.weeks[safeWeek]
        let safeDay = min(dayIdx, week.days.count - 1)
        return ProgramSessionRequest(weekNumber: week.weekNumber, day: week.days[safeDay])
    }
}

struct ProgramSessionRequest: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let day: ProgramDay
}
