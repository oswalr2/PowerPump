import SwiftUI

struct WorkoutsView: View {
    @ObservedObject private var store = WorkoutStore.shared
    @State private var showActive = false
    @State private var showSaveRoutine = false
    @State private var showRunning = false
    @State private var showRunningPrograms = false
    @State private var routineName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header

                        // Resume banner if there's an orphan session
                        if store.activeSession != nil {
                            resumeBanner
                        }

                        startButton

                        runCard

                        runningProgramsCard

                        programsSection

                        exerciseLibraryLink

                        if !store.templates.isEmpty { routinesSection }

                        if !store.history.isEmpty { historySection }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showActive) {
            ActiveWorkoutView(isPresented: $showActive)
        }
        .fullScreenCover(isPresented: $showRunning) {
            RunningView()
        }
        .sheet(isPresented: $showRunningPrograms) {
            RunningProgramsView()
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Text("Workouts")
                .font(SBFont.display(28))
                .foregroundColor(.sbTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var resumeBanner: some View {
        Button { showActive = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.sbAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workout in progress")
                        .font(SBFont.heading(14))
                        .foregroundColor(.sbTextPrimary)
                    Text("Tap to resume")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.sbAccent)
            }
            .padding(16)
            .background(Color.sbAccent.opacity(0.1))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbAccent.opacity(0.4)))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private var startButton: some View {
        Button {
            store.startEmpty()
            showActive = true
        } label: {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Start Empty Workout")
                    .font(SBFont.body())
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(.white)
            .padding(18)
            .background(Color.sbAccent)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: - Walking & Running Programs

    private var runningProgramsCard: some View {
        Button {
            HapticManager.medium()
            showRunningPrograms = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.sbAccent.opacity(0.35), Color.sbAccent.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.sbAccent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Walk & Run Programs")
                        .font(SBFont.heading(16))
                        .foregroundColor(.sbTextPrimary)
                    Text("Lose weight · 5K · Pace · Voice coach")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.sbTextSecondary.opacity(0.6))
            }
            .padding(16)
            .background(Color.sbSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbAccent.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: - Run / Walk

    private var runCard: some View {
        Button {
            HapticManager.medium()
            showRunning = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.sbAccent.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: "figure.run")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.sbAccent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Run / Walk")
                        .font(SBFont.heading(16))
                        .foregroundColor(.sbTextPrimary)
                    Text("GPS · Live route · Pace & calories")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.sbTextSecondary.opacity(0.6))
            }
            .padding(16)
            .background(Color.sbSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbAccent.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: - Programs

    private var programsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Programs")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(ProgramLibrary.all) { program in
                    ProgramCard(program: program) {
                        store.start(template: program.template)
                        HapticManager.medium()
                        showActive = true
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var exerciseLibraryLink: some View {
        NavigationLink(destination: ExercisesView()) {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 18))
                    .foregroundColor(.sbAccent)
                Text("Exercise Library")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.sbTextSecondary)
            }
            .padding(16)
            .background(Color.sbSurface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Routines")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)
                .padding(.horizontal, 20)

            ForEach(store.templates) { template in
                TemplateCard(template: template) {
                    store.start(template: template)
                    showActive = true
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)
                .padding(.horizontal, 20)

            ForEach(store.history.prefix(5)) { session in
                HistoryCard(session: session)
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: WorkoutTemplate
    let onStart: () -> Void
    @ObservedObject private var store = WorkoutStore.shared

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
                Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
            }

            Spacer()

            Button(action: onStart) {
                Text("Start")
                    .font(SBFont.caption())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.sbAccent)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.sbSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.deleteTemplate(template)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - History Card

private struct HistoryCard: View {
    let session: WorkoutSession

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: session.startedAt)
    }

    private var durationString: String {
        let m = Int(session.duration) / 60
        return m < 60 ? "\(m) min" : String(format: "%dh %02dm", m / 60, m % 60)
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
                Text(dateString)
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(durationString)
                    .font(SBFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(.sbAccent)
                Text("\(session.completedSets) sets · \(Int(session.totalVolume)) kg")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
            }
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
    }
}

// MARK: - Exercise Picker Sheet

struct ExercisePickerView: View {
    let onSelect: (String) -> Void
    @State private var searchText = ""
    @State private var selectedCategory: MuscleGroup? = nil
    @Environment(\.dismiss) private var dismiss

    private var filtered: [Exercise] {
        var list = ExerciseDatabase.all
        if let cat = selectedCategory { list = list.filter { $0.category == cat } }
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(.sbTextSecondary)
                        TextField("Search exercises...", text: $searchText)
                            .font(SBFont.body())
                            .foregroundColor(.sbTextPrimary)
                    }
                    .padding(12)
                    .background(Color.sbSurface)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
                    .padding(16)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(MuscleGroup.allCases, id: \.self) { g in
                                FilterChip(label: g.rawValue, isSelected: selectedCategory == g) {
                                    selectedCategory = selectedCategory == g ? nil : g
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(filtered) { exercise in
                                Button { onSelect(exercise.id) } label: {
                                    HStack(spacing: 12) {
                                        if let name = ExerciseDatabase.muscleIconNames[exercise.id],
                                           let img = UIImage(named: name) {
                                            Image(uiImage: img)
                                                .resizable().scaledToFill()
                                                .frame(width: 42, height: 42)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.sbSurfaceRaised)
                                                .frame(width: 42, height: 42)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.name)
                                                .font(SBFont.body())
                                                .foregroundColor(.sbTextPrimary)
                                            Text(exercise.primaryMuscle)
                                                .font(SBFont.caption())
                                                .foregroundColor(.sbTextSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.sbAccent)
                                    }
                                    .padding(12)
                                    .background(Color.sbSurface)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.sbAccent)
                }
            }
        }
    }
}

// MARK: - Program Card

private struct ProgramCard: View {
    let program: BuiltinProgram
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Icon on the left
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.sbAccent.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: program.icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color.sbAccent)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(SBFont.heading(17))
                    .foregroundColor(.sbTextPrimary)

                Text(program.subtitle)
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Label("\(program.estimatedMinutes) min", systemImage: "clock")
                    Circle().fill(Color.sbBorder).frame(width: 3, height: 3)
                    Label("\(program.template.exercises.count)", systemImage: "list.bullet")
                }
                .font(SBFont.label(11))
                .foregroundColor(.sbTextSecondary)
                .labelStyle(.titleAndIcon)
                .padding(.top, 2)
            }

            Spacer()

            // Start button on the right
            Button(action: onStart) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.sbAccent)
                    .clipShape(Circle())
                    .shadow(color: Color.sbAccent.opacity(0.4), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.sbAccent.opacity(0.25), lineWidth: 1.5))
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(SBFont.caption())
                .foregroundColor(isSelected ? .white : .sbTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.sbAccent : Color.sbSurface)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.sbAccent : Color.sbBorder))
        }
        .buttonStyle(.plain)
    }
}
