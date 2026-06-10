import SwiftUI

struct WatchWorkoutView: View {
    @ObservedObject private var store   = WatchConnectivityManager.shared
    @ObservedObject private var workout = WatchWorkoutManager.shared
    @State private var showFinishAlert  = false

    var body: some View {
        Group {
            if workout.isRunning {
                activeView
            } else {
                idleView
            }
        }
    }

    // MARK: - Idle (no active workout)

    private var idleView: some View {
        VStack(spacing: 10) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.blue)

            if store.hasActiveWorkout {
                Text(store.activeWorkoutName.isEmpty ? "Workout" : store.activeWorkoutName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Button {
                    workout.startWorkout(exerciseName: store.currentExercise)
                } label: {
                    Label("Start Tracking", systemImage: "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            } else {
                Text("No active workout")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                Text("Start one on your iPhone")
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .onAppear { workout.requestAuthorization() }
    }

    // MARK: - Active workout

    private var activeView: some View {
        ScrollView {
            VStack(spacing: 8) {

                // Timer
                Text(workout.elapsedFormatted)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                // Heart rate
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                    Text(workout.heartRate > 0 ? "\(workout.heartRate) bpm" : "—")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Exercise name
                if !workout.currentExercise.isEmpty {
                    Text(workout.currentExercise)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                // Sets counter
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                    Text("\(workout.setsCompleted) sets done")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Complete set button
                Button {
                    workout.completeSet()
                } label: {
                    Label("Set Done", systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                // Finish button
                Button {
                    showFinishAlert = true
                } label: {
                    Text("Finish")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.horizontal, 8)
        }
        .alert("Finish Workout?", isPresented: $showFinishAlert) {
            Button("Finish", role: .destructive) { workout.finishWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(workout.setsCompleted) sets · \(workout.elapsedFormatted)")
        }
    }
}
