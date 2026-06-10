import Foundation
import HealthKit
import WatchKit

final class WatchWorkoutManager: NSObject, ObservableObject {
    static let shared = WatchWorkoutManager()

    @Published var isRunning = false
    @Published var heartRate: Int = 0
    @Published var elapsedSeconds: Int = 0
    @Published var setsCompleted: Int = 0
    @Published var currentExercise: String = ""
    @Published var authDenied = false

    private let hk = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var timer: Timer?

    override private init() { super.init() }

    // MARK: - Authorization

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set<HKSampleType> = [HKQuantityType(.activeEnergyBurned), HKObjectType.workoutType()]
        let read:  Set<HKObjectType> = [HKQuantityType(.heartRate), HKQuantityType(.activeEnergyBurned)]
        hk.requestAuthorization(toShare: share, read: read) { _, _ in }
    }

    // MARK: - Session control

    func startWorkout(exerciseName: String) {
        currentExercise = exerciseName
        setsCompleted = 0
        elapsedSeconds = 0

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType  = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: hk, configuration: config)
            let liveBuilder = session.associatedWorkoutBuilder()
            liveBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: hk, workoutConfiguration: config)
            session.delegate  = self
            liveBuilder.delegate = self
            workoutSession = session
            builder = liveBuilder
            session.startActivity(with: .now)
            liveBuilder.beginCollection(withStart: .now) { _, _ in }
        } catch {
            startTimerOnly()
            return
        }

        isRunning = true
        startTimer()
    }

    func completeSet() {
        setsCompleted += 1
        WKInterfaceDevice.current().play(.success)
    }

    func finishWorkout() {
        timer?.invalidate()
        timer = nil
        workoutSession?.end()
        builder?.endCollection(withEnd: .now) { [weak self] _, _ in
            self?.builder?.finishWorkout { _, _ in }
        }
        isRunning = false
        WatchConnectivityManager.shared.sendWorkoutFinished(
            duration: elapsedSeconds,
            sets: setsCompleted
        )
        heartRate = 0
        elapsedSeconds = 0
        setsCompleted = 0
    }

    // MARK: - Timer fallback (when HealthKit unavailable)

    private func startTimerOnly() {
        isRunning = true
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    var elapsedFormatted: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ session: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {}

    func workoutSession(_ session: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async { self.isRunning = false }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ builder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(hrType) else { return }
        let stats = builder.statistics(for: hrType)
        let bpm   = stats?.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
        DispatchQueue.main.async { self.heartRate = Int(bpm) }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
