import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var selectedTab = 0
    @State private var showLogSheet = false
    @State private var showFormCheck = false
    @Environment(\.dismiss) private var dismiss

    private var supportedExercise: SupportedExercise? {
        SupportedExercise.allCases.first { $0.rawValue == exercise.id }
    }

    var body: some View {
        ZStack {
            Color.sbBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Hero animation banner (full width, nav overlaid) ──
                ZStack(alignment: .top) {
                    // Animation fills the entire hero area
                    ExerciseAnimationView(exercise: exercise)
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .background(Color.sbSurface)

                    // Navigation overlay on top of the animation
                    HStack {
                        Button { dismiss() } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.sbBackground.opacity(0.6))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.sbTextPrimary)
                            }
                        }
                        Spacer()
                        Text(exercise.category.rawValue.uppercased())
                            .font(SBFont.label(12))
                            .foregroundColor(.sbAccent)
                            .tracking(2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.sbBackground.opacity(0.6))
                            .cornerRadius(20)
                        Spacer()
                        Color.clear.frame(width: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 52)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        // ── Exercise name + badges ─────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.name)
                                .font(SBFont.display(26))
                                .foregroundColor(.sbTextPrimary)
                            HStack(spacing: 8) {
                                DifficultyBadge(difficulty: exercise.difficulty)
                                LocationBadge(label: exercise.location.rawValue)
                                LocationBadge(label: exercise.equipment.rawValue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                        // ── Stats ──────────────────────────────────────
                        HStack(spacing: 0) {
                            StatItem(label: "Sets",  value: "\(exercise.defaultSets)")
                            Divider().frame(width: 1, height: 36).background(Color.sbBorder)
                            StatItem(label: "Reps",  value: exercise.defaultReps)
                            Divider().frame(width: 1, height: 36).background(Color.sbBorder)
                            StatItem(label: "Primary", value: exercise.primaryMuscle)
                        }
                        .background(Color.sbSurface)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                        // ── Tabs ───────────────────────────────────────
                        HStack(spacing: 0) {
                            TabButton(title: "Instructions", index: 0, selected: $selectedTab)
                            TabButton(title: "History",      index: 1, selected: $selectedTab)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                        if selectedTab == 0 {
                            InstructionsTab(exercise: exercise)
                        } else {
                            HistoryTab(exerciseId: exercise.id)
                        }
                    }
                    .padding(.bottom, 120)
                }
            }

            // Bottom buttons
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    if supportedExercise != nil {
                        Button {
                            showFormCheck = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                Text("Check Form")
                            }
                            .font(SBFont.body())
                            .fontWeight(.semibold)
                            .foregroundColor(.sbAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.sbAccentDim)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbAccent.opacity(0.4), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }

                    SBPrimaryButton(title: "Log Exercise") {
                        showLogSheet = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showLogSheet) {
            LogExerciseSheet(exercise: exercise, isPresented: $showLogSheet)
        }
        .fullScreenCover(isPresented: $showFormCheck) {
            if let supported = supportedExercise {
                ExerciseCorrectionView(exercise: supported)
            }
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(SBFont.heading(16))
                .foregroundColor(.sbTextPrimary)
                .multilineTextAlignment(.center)
            Text(label)
                .font(SBFont.label(11))
                .foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MuscleRow: View {
    let label: String
    let muscle: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .frame(width: 68, alignment: .leading)
            Text(muscle)
                .font(SBFont.caption())
                .foregroundColor(.sbTextPrimary)
        }
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let title: String
    let index: Int
    @Binding var selected: Int

    var body: some View {
        Button { withAnimation(.spring(response: 0.25)) { selected = index } } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(SBFont.heading(15))
                    .foregroundColor(selected == index ? .sbTextPrimary : .sbTextSecondary)
                Rectangle()
                    .fill(selected == index ? Color.sbAccent : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Instructions Tab

private struct InstructionsTab: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Setup
            SectionBlock(title: "Setup") {
                Text(exercise.setup)
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .lineSpacing(4)
            }

            // Steps
            SectionBlock(title: "Execution") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(exercise.steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.sbAccent)
                                    .frame(width: 26, height: 26)
                                Text("\(i + 1)")
                                    .font(SBFont.label(12))
                                    .foregroundColor(.white)
                            }
                            Text(step)
                                .font(SBFont.body())
                                .foregroundColor(.sbTextSecondary)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            // Tips
            if !exercise.tips.isEmpty {
                SectionBlock(title: "Tips") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(exercise.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.sbAccent)
                                    .padding(.top, 2)
                                Text(tip)
                                    .font(SBFont.body())
                                    .foregroundColor(.sbTextSecondary)
                                    .lineSpacing(3)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct SectionBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(SBFont.label(12))
                .foregroundColor(.sbAccent)
                .tracking(2)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sbSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder, lineWidth: 1))
    }
}

// MARK: - History Tab

private struct HistoryTab: View {
    let exerciseId: String

    private var logs: [ExerciseLog] {
        ExerciseLogStore.shared.logs(for: exerciseId)
    }

    var body: some View {
        if logs.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 44))
                    .foregroundColor(.sbBorder)
                Text("No logs yet")
                    .font(SBFont.heading(18))
                    .foregroundColor(.sbTextSecondary)
                Text("Log this exercise to start tracking your progress.")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(logs) { log in
                    LogCard(log: log)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct LogCard: View {
    let log: ExerciseLog

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(log.date.formatted(date: .abbreviated, time: .omitted))
                .font(SBFont.label(12))
                .foregroundColor(.sbAccent)
                .tracking(1)

            HStack(spacing: 0) {
                Text("Set").font(SBFont.label(11)).foregroundColor(.sbTextSecondary).frame(maxWidth: .infinity)
                Text("Reps").font(SBFont.label(11)).foregroundColor(.sbTextSecondary).frame(maxWidth: .infinity)
                Text("Weight").font(SBFont.label(11)).foregroundColor(.sbTextSecondary).frame(maxWidth: .infinity)
            }

            ForEach(Array(log.sets.enumerated()), id: \.offset) { i, set in
                HStack(spacing: 0) {
                    Text("\(i + 1)").font(SBFont.body()).foregroundColor(.sbTextPrimary).frame(maxWidth: .infinity)
                    Text("\(set.reps)").font(SBFont.body()).foregroundColor(.sbTextPrimary).frame(maxWidth: .infinity)
                    Text(set.weightKg > 0 ? "\(String(format: "%.1f", set.weightKg)) kg" : "BW")
                        .font(SBFont.body()).foregroundColor(.sbTextPrimary).frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder, lineWidth: 1))
    }
}

// MARK: - Log Exercise Sheet

struct LogExerciseSheet: View {
    let exercise: Exercise
    @Binding var isPresented: Bool
    @State private var sets: [WorkoutSet] = [WorkoutSet(), WorkoutSet(), WorkoutSet()]

    var body: some View {
        ZStack {
            Color.sbBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.sbBorder)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                HStack {
                    Text("Log: \(exercise.name)")
                        .font(SBFont.heading(18))
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.sbBorder)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Column headers
                HStack {
                    Text("SET").font(SBFont.label(11)).foregroundColor(.sbTextSecondary).frame(width: 36)
                    Spacer()
                    Text("WEIGHT (kg)").font(SBFont.label(11)).foregroundColor(.sbTextSecondary).frame(width: 110)
                    Spacer()
                    Text("REPS").font(SBFont.label(11)).foregroundColor(.sbTextSecondary).frame(width: 70)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

                Divider().background(Color.sbBorder).padding(.horizontal, 20)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(sets.indices, id: \.self) { i in
                            SetRow(index: i, set: $sets[i])
                            Divider().background(Color.sbBorder).padding(.horizontal, 20)
                        }
                    }
                }

                // Add Set
                Button {
                    sets.append(WorkoutSet())
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Set")
                    }
                    .font(SBFont.body())
                    .foregroundColor(.sbAccent)
                    .padding(.vertical, 14)
                }

                SBPrimaryButton(title: "Save Log") {
                    ExerciseLogStore.shared.save(ExerciseLog(exerciseId: exercise.id, sets: sets))
                    isPresented = false
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct SetRow: View {
    let index: Int
    @Binding var set: WorkoutSet

    var body: some View {
        HStack {
            Text("\(index + 1)")
                .font(SBFont.heading(16))
                .foregroundColor(.sbTextSecondary)
                .frame(width: 36)

            Spacer()

            // Weight stepper
            HStack(spacing: 0) {
                StepButton(icon: "minus") {
                    if set.weightKg >= 2.5 { set.weightKg -= 2.5 }
                }
                Text(set.weightKg > 0 ? String(format: "%.1f", set.weightKg) : "BW")
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
                    .frame(width: 60)
                StepButton(icon: "plus") { set.weightKg += 2.5 }
            }
            .background(Color.sbSurface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.sbBorder))
            .frame(width: 110)

            Spacer()

            // Reps stepper
            HStack(spacing: 0) {
                StepButton(icon: "minus") { if set.reps > 1 { set.reps -= 1 } }
                Text("\(set.reps)")
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
                    .frame(width: 36)
                StepButton(icon: "plus") { set.reps += 1 }
            }
            .background(Color.sbSurface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.sbBorder))
            .frame(width: 70)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

private struct StepButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.sbTextSecondary)
                .frame(width: 30, height: 36)
        }
    }
}
