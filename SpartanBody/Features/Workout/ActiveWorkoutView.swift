import SwiftUI
import AudioToolbox

// MARK: - Active Workout (full-screen)

struct ActiveWorkoutView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var store = WorkoutStore.shared

    @State private var elapsedSeconds = 0
    @State private var clockTimer: Timer?

    @State private var showRestTimer = false
    @State private var restSeconds = 90

    @State private var showExercisePicker = false
    @State private var showFinishDialog = false
    @State private var showSaveRoutine = false
    @State private var routineName = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.sbBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if let session = store.activeSession {
                            ForEach(Array(session.exercises.enumerated()), id: \.element.id) { exIdx, ex in
                                ExerciseCard(
                                    sessionExercise: ex,
                                    exerciseIndex: exIdx,
                                    onSetCompleted: {
                                        let saved = UserDefaults.standard.integer(forKey: "sb_rest_duration")
                                        restSeconds = saved > 0 ? saved : 90
                                        withAnimation(.spring(response: 0.4)) { showRestTimer = true }
                                    }
                                )
                            }
                        }

                        addExerciseButton
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }

            // Rest timer sheet
            if showRestTimer {
                Color.black.opacity(0.45).ignoresSafeArea()
                    .onTapGesture { withAnimation { showRestTimer = false } }
                    .transition(.opacity)

                RestTimerView(seconds: $restSeconds, isShowing: $showRestTimer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 32)
            }
        }
        .onAppear { startClock() }
        .onDisappear { clockTimer?.invalidate() }
        .onChange(of: showRestTimer) { showing in
            if showing {
                WorkoutLiveActivityManager.shared.startRest(seconds: restSeconds, session: store.activeSession)
            } else {
                WorkoutLiveActivityManager.shared.endRest(session: store.activeSession)
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { id in
                store.addExercise(id)
                showExercisePicker = false
            }
        }
        .sheet(isPresented: $showSaveRoutine) {
            SaveRoutineSheet(routineName: $routineName) {
                store.saveAsTemplate(name: routineName.isEmpty ? "My Routine" : routineName)
                HapticManager.heavy()
                store.finish()
                isPresented = false
            } onSkip: {
                HapticManager.heavy()
                store.finish()
                isPresented = false
            }
        }
        .confirmationDialog("Finish Workout?", isPresented: $showFinishDialog, titleVisibility: .visible) {
            Button("Save as Routine & Finish") {
                routineName = store.activeSession?.name ?? "My Routine"
                showSaveRoutine = true
            }
            Button("Just Finish") {
                HapticManager.heavy()
                store.finish()
                isPresented = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let sets = store.activeSession?.completedSets ?? 0
            Text("\(sets) set\(sets == 1 ? "" : "s") completed")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                store.cancel()
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.sbTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.sbSurface)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(store.activeSession?.name ?? "Workout")
                    .font(SBFont.heading(16))
                    .foregroundColor(.sbTextPrimary)
                Text(formatTime(elapsedSeconds))
                    .font(SBFont.caption())
                    .foregroundColor(.sbAccent)
                    .monospacedDigit()
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    HapticManager.light()
                    let saved = UserDefaults.standard.integer(forKey: "sb_rest_duration")
                    restSeconds = saved > 0 ? saved : 90
                    withAnimation(.spring(response: 0.4)) { showRestTimer = true }
                } label: {
                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(showRestTimer ? .sbAccent : .sbTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.sbSurface)
                        .clipShape(Circle())
                }

                Button { showFinishDialog = true } label: {
                    Text("Finish")
                        .font(SBFont.caption())
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Color.sbAccent)
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.sbSurface)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.sbBorder), alignment: .bottom)
    }

    private var addExerciseButton: some View {
        Button { showExercisePicker = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add Exercise")
            }
            .font(SBFont.body())
            .foregroundColor(.sbAccent)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.sbAccentDim)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbAccent.opacity(0.35)))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func startClock() {
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func formatTime(_ s: Int) -> String {
        s < 3600
            ? String(format: "%d:%02d", s / 60, s % 60)
            : String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
}

// MARK: - Exercise Card

private struct ExerciseCard: View {
    let sessionExercise: SessionExercise
    let exerciseIndex: Int
    let onSetCompleted: () -> Void
    @ObservedObject private var store = WorkoutStore.shared
    @State private var showFormCheck = false

    private var exercise: Exercise? {
        ExerciseDatabase.all.first { $0.id == sessionExercise.exerciseID }
    }

    private var supportedExercise: SupportedExercise? {
        SupportedExercise.allCases.first { $0.rawValue == sessionExercise.exerciseID }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                if let name = ExerciseDatabase.muscleIconNames[sessionExercise.exerciseID],
                   let img = UIImage(named: name) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise?.name ?? sessionExercise.exerciseID)
                        .font(SBFont.heading(15))
                        .foregroundColor(.sbTextPrimary)
                    if let pr = store.personalRecord(for: sessionExercise.exerciseID) {
                        HStack(spacing: 3) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "#FFD700"))
                            Text("PR: \(String(format: "%.1f", pr.weight)) kg × \(pr.reps)")
                                .font(SBFont.label(10))
                                .foregroundColor(.sbTextSecondary)
                        }
                    } else {
                        Text(exercise?.primaryMuscle ?? "")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    }
                }

                Spacer()

                Text("\(sessionExercise.completedSetCount)/\(sessionExercise.sets.count)")
                    .font(SBFont.caption())
                    .fontWeight(.bold)
                    .foregroundColor(.sbAccent)

                if supportedExercise != nil {
                    Button { showFormCheck = true } label: {
                        Image(systemName: "camera")
                            .font(.system(size: 14))
                            .foregroundColor(.sbAccent)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    store.removeExercise(at: exerciseIndex)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.sbTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .fullScreenCover(isPresented: $showFormCheck) {
                if let supported = supportedExercise {
                    ExerciseCorrectionView(exercise: supported)
                }
            }

            Divider().background(Color.sbBorder)

            // Column headers
            HStack {
                Text("SET").frame(width: 40, alignment: .center)
                Text("KG").frame(maxWidth: .infinity)
                Text("REPS").frame(maxWidth: .infinity)
                Text("").frame(width: 44)
            }
            .font(SBFont.label(10))
            .foregroundColor(.sbTextSecondary)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 4)

            // Set rows
            ForEach(Array(sessionExercise.sets.enumerated()), id: \.element.id) { setIdx, set in
                SetRow(
                    set: set,
                    exerciseIndex: exerciseIndex,
                    setIndex: setIdx,
                    exerciseID: sessionExercise.exerciseID,
                    onComplete: onSetCompleted
                )
            }

            // Add set
            Button { store.addSet(to: exerciseIndex) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                    Text("Add Set")
                }
                .font(SBFont.caption())
                .foregroundColor(.sbAccent)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .background(Color.sbSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
        .padding(.horizontal, 20)
    }
}

// MARK: - Set Row

private struct SetRow: View {
    let set: SessionSet
    let exerciseIndex: Int
    let setIndex: Int
    let exerciseID: String
    let onComplete: () -> Void
    @ObservedObject private var store = WorkoutStore.shared

    @State private var weightText: String
    @State private var repsText: String
    @State private var showPR = false

    init(set: SessionSet, exerciseIndex: Int, setIndex: Int, exerciseID: String, onComplete: @escaping () -> Void) {
        self.set = set
        self.exerciseIndex = exerciseIndex
        self.setIndex = setIndex
        self.exerciseID = exerciseID
        self.onComplete = onComplete
        _weightText = State(initialValue: set.weight > 0 ? String(format: "%.1f", set.weight) : "")
        _repsText   = State(initialValue: "\(set.reps)")
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("\(set.setNumber)")
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
                .frame(width: 40, alignment: .center)

            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(SBFont.body())
                .fontWeight(set.completed ? .bold : .regular)
                .foregroundColor(set.completed ? .sbAccent : .sbTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color.sbSurfaceRaised)
                .cornerRadius(8)
                .onChange(of: weightText) { val in
                    if let w = Double(val) { store.updateWeight(w, exerciseIndex: exerciseIndex, setIndex: setIndex) }
                }

            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(SBFont.body())
                .fontWeight(set.completed ? .bold : .regular)
                .foregroundColor(set.completed ? .sbAccent : .sbTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color.sbSurfaceRaised)
                .cornerRadius(8)
                .onChange(of: repsText) { val in
                    if let r = Int(val) { store.updateReps(r, exerciseIndex: exerciseIndex, setIndex: setIndex) }
                }

            Button {
                let w = Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? set.weight
                let r = Int(repsText) ?? set.reps
                let isNewPR = !set.completed && store.isNewRecord(exerciseID: exerciseID, weight: w, reps: r)
                let nowComplete = store.toggleSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
                if nowComplete {
                    if isNewPR {
                        HapticManager.heavy()
                        showPR = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showPR = false }
                    } else {
                        HapticManager.success()
                    }
                    onComplete()
                } else {
                    HapticManager.light()
                }
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundColor(set.completed ? .sbAccent : .sbBorder)
                    .animation(.spring(response: 0.3), value: set.completed)
            }
            .buttonStyle(.plain)
            .frame(width: 44)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .background(set.completed ? Color.sbAccent.opacity(0.06) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: set.completed)
        .overlay(alignment: .trailing) {
            if showPR {
                Text("🏆 PR!")
                    .font(SBFont.caption())
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#FFD700"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#FFD700").opacity(0.15))
                    .cornerRadius(8)
                    .transition(.scale.combined(with: .opacity))
                    .padding(.trailing, 52)
            }
        }
        .animation(.spring(response: 0.3), value: showPR)
    }
}

// MARK: - Rest Timer

struct RestTimerView: View {
    @Binding var seconds: Int
    @Binding var isShowing: Bool
    @State private var countdown: Timer?
    @State private var total: Int = {
        let saved = UserDefaults.standard.integer(forKey: "sb_rest_duration")
        return saved > 0 ? saved : 90
    }()
    @State private var isDone = false

    private let presets = [60, 90, 120, 180]

    private var ringColor: Color {
        if isDone { return .sbGreen }
        if seconds <= 10 { return .sbRed }
        if seconds <= 30 { return Color.orange }
        return .sbAccent
    }

    private var progress: CGFloat {
        total > 0 ? CGFloat(seconds) / CGFloat(total) : 0
    }

    var body: some View {
        VStack(spacing: 18) {
            // Header
            HStack {
                Text("Rest Timer")
                    .font(SBFont.heading())
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Button { dismissTimer() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.sbTextSecondary)
                }
            }

            // Preset duration buttons
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        HapticManager.light()
                        total = preset
                        seconds = preset
                        UserDefaults.standard.set(preset, forKey: "sb_rest_duration")
                        isDone = false
                        restartCountdown()
                    } label: {
                        Text(presetLabel(preset))
                            .font(SBFont.label(12))
                            .fontWeight(.semibold)
                            .foregroundColor(total == preset ? .white : .sbTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(total == preset ? Color.sbAccent : Color.sbSurfaceRaised)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color.sbBorder, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(1, progress))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: seconds)

                if isDone {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.sbGreen)
                        Text("Done!")
                            .font(SBFont.heading(16))
                            .foregroundColor(.sbGreen)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    VStack(spacing: 4) {
                        Text(formatTime(seconds))
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(seconds <= 10 ? ringColor : .sbTextPrimary)
                            .monospacedDigit()
                            .animation(.none, value: seconds)
                        Text("rest")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    }
                }
            }
            .frame(width: 160, height: 160)

            // Adjust -15 / Skip / +15
            HStack(spacing: 12) {
                adjustButton("-15") { seconds = max(0, seconds - 15) }

                Button { dismissTimer() } label: {
                    Text("Skip Rest")
                        .font(SBFont.body())
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.sbAccent)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                adjustButton("+15") { seconds = min(300, seconds + 15) }
            }
        }
        .padding(24)
        .background(Color.sbSurface)
        .cornerRadius(28)
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.sbBorder))
        .padding(.horizontal, 20)
        .onAppear { startCountdown() }
        .onDisappear { countdown?.invalidate() }
    }

    private func startCountdown() {
        countdown?.invalidate()
        countdown = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if seconds > 0 {
                seconds -= 1
            } else {
                timerFinished()
            }
        }
    }

    private func restartCountdown() {
        countdown?.invalidate()
        startCountdown()
    }

    private func timerFinished() {
        countdown?.invalidate()
        withAnimation(.spring(response: 0.3)) { isDone = true }
        HapticManager.heavy()
        AudioServicesPlaySystemSound(1057)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.35)) { isShowing = false }
        }
    }

    private func dismissTimer() {
        countdown?.invalidate()
        withAnimation(.spring(response: 0.35)) { isShowing = false }
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }

    private func presetLabel(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }

    private func adjustButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(SBFont.body())
                .fontWeight(.semibold)
                .foregroundColor(.sbTextPrimary)
                .frame(width: 64)
                .padding(.vertical, 13)
                .background(Color.sbSurfaceRaised)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Save Routine Sheet

private struct SaveRoutineSheet: View {
    @Binding var routineName: String
    let onSave: () -> Void
    let onSkip: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "bookmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.sbAccent)

                    VStack(spacing: 8) {
                        Text("Save as Routine?")
                            .font(SBFont.heading(22))
                            .foregroundColor(.sbTextPrimary)
                        Text("Save this workout so you can start it again with one tap.")
                            .font(SBFont.body())
                            .foregroundColor(.sbTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    TextField("Routine name…", text: $routineName)
                        .font(SBFont.body())
                        .foregroundColor(.sbTextPrimary)
                        .padding(14)
                        .background(Color.sbSurface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))

                    VStack(spacing: 12) {
                        Button(action: onSave) {
                            Text("Save & Finish")
                                .font(SBFont.body())
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.sbAccent)
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)

                        Button(action: onSkip) {
                            Text("Finish without saving")
                                .font(SBFont.body())
                                .foregroundColor(.sbTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(28)
            }
            .navigationBarHidden(true)
        }
    }
}
