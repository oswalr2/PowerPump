import HealthKit
import Foundation

struct HeartRateSample: Identifiable {
    let id   = UUID()
    let date: Date
    let bpm:  Double
}

final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    private let hk = HKHealthStore()

    @Published var isAvailable  = HKHealthStore.isHealthDataAvailable()
    @Published var isAuthorized = false
    @Published var stepsToday:        Int    = 0
    @Published var activeEnergyToday: Double = 0
    @Published var weeklyHeartRate:   [HeartRateSample] = []

    // MARK: - Types

    private static let writeIDs: [HKQuantityTypeIdentifier] = [
        .activeEnergyBurned,
        .dietaryEnergyConsumed,
        .dietaryProtein,
        .dietaryCarbohydrates,
        .dietaryFatTotal,
        .dietaryWater,
        .bodyMass,
        .distanceWalkingRunning,
    ]

    private static let readIDs: [HKQuantityTypeIdentifier] = [
        .stepCount,
        .activeEnergyBurned,
        .bodyMass,
        .heartRate,
    ]

    private var shareTypes: Set<HKSampleType> {
        let qtypes = Self.writeIDs.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
        return Set(qtypes + [HKObjectType.workoutType()])
    }

    private var readTypes: Set<HKObjectType> {
        Set(Self.readIDs.compactMap { HKQuantityType.quantityType(forIdentifier: $0) })
    }

    private init() {
        guard isAvailable else { return }
        let probe = HKQuantityType(.stepCount)
        isAuthorized = hk.authorizationStatus(for: probe) == .sharingAuthorized
        if isAuthorized { fetchTodayStats() }
    }

    // MARK: - Authorization

    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        guard isAvailable else { completion(false); return }
        hk.requestAuthorization(toShare: shareTypes, read: readTypes) { [weak self] ok, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = ok
                if ok { self?.fetchTodayStats() }
                completion(ok)
            }
        }
    }

    // MARK: - Read

    func fetchTodayStats() {
        fetchSum(.stepCount, unit: .count()) { [weak self] v in
            DispatchQueue.main.async { self?.stepsToday = Int(v) }
        }
        fetchSum(.activeEnergyBurned, unit: .kilocalorie()) { [weak self] v in
            DispatchQueue.main.async { self?.activeEnergyToday = v }
        }
        fetchWeeklyHeartRate()
        fetchLatestBodyMass()
    }

    /// Pulls the most recent body-mass sample from Apple Health (e.g. from a
    /// smart scale or the Health app) and forwards it to UserProfile +
    /// ProgressStore so the rest of the app sees it as a fresh weigh-in.
    func fetchLatestBodyMass() {
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type,
                                  predicate: nil,
                                  limit: 1,
                                  sortDescriptors: [sort]) { _, samples, _ in
            guard let s = samples?.first as? HKQuantitySample else { return }
            let kg = s.quantity.doubleValue(for: .gramUnit(with: .kilo))
            let date = s.endDate
            DispatchQueue.main.async {
                ProgressStore.shared.addEntry(weightKg: kg, date: date)
                if abs(UserProfile.shared.weightKg - kg) > 0.05 {
                    UserProfile.shared.weightKg = kg
                }
            }
        }
        hk.execute(query)
    }

    func fetchWeeklyHeartRate() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let cal       = Calendar.current
        let today     = cal.startOfDay(for: .now)
        guard let weekStart = cal.date(byAdding: .day, value: -6, to: today) else { return }

        let interval   = DateComponents(day: 1)
        let predicate  = HKQuery.predicateForSamples(withStart: weekStart, end: .now)
        let anchorDate = cal.startOfDay(for: weekStart)

        let query = HKStatisticsCollectionQuery(
            quantityType: hrType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage,
            anchorDate: anchorDate,
            intervalComponents: interval
        )

        query.initialResultsHandler = { [weak self] _, results, _ in
            guard let results else { return }
            var samples: [HeartRateSample] = []
            results.enumerateStatistics(from: weekStart, to: .now) { stat, _ in
                if let qty = stat.averageQuantity() {
                    let bpm = qty.doubleValue(for: HKUnit(from: "count/min"))
                    samples.append(HeartRateSample(date: stat.startDate, bpm: bpm))
                }
            }
            DispatchQueue.main.async { self?.weeklyHeartRate = samples }
        }

        hk.execute(query)
    }

    private func fetchSum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { completion(0); return }
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        let query = HKStatisticsQuery(quantityType: type,
                                       quantitySamplePredicate: predicate,
                                       options: .cumulativeSum) { _, result, _ in
            completion(result?.sumQuantity()?.doubleValue(for: unit) ?? 0)
        }
        hk.execute(query)
    }

    // MARK: - Write: Workout

    func saveWorkout(_ session: WorkoutSession) {
        guard isAvailable, let end = session.finishedAt else { return }
        let kcal = session.duration / 60 * 6
        let energy = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
        let workout = HKWorkout(activityType: .traditionalStrengthTraining,
                                start: session.startedAt,
                                end: end,
                                duration: session.duration,
                                totalEnergyBurned: energy,
                                totalDistance: nil,
                                metadata: nil)
        hk.save(workout) { _, _ in }
    }

    // MARK: - Write: Run / Walk / Hike

    func saveRun(_ session: RunSession) {
        guard isAvailable, let end = session.endedAt else { return }
        let activity: HKWorkoutActivityType = {
            switch session.activity {
            case .run:  return .running
            case .walk: return .walking
            case .hike: return .hiking
            }
        }()
        let energy = HKQuantity(unit: .kilocalorie(), doubleValue: Double(session.calories))
        let distance = HKQuantity(unit: .meter(), doubleValue: session.distanceMeters)
        let workout = HKWorkout(activityType: activity,
                                start: session.startedAt,
                                end: end,
                                duration: session.movingSeconds,
                                totalEnergyBurned: energy,
                                totalDistance: distance,
                                metadata: nil)
        hk.save(workout) { _, _ in }
    }

    // MARK: - Write: Generic Sport

    /// Saves a finished sport session as an HKWorkout with the sport's
    /// HealthKit activity type, total moving time, distance (if any) and
    /// energy burned.  Distance is only attached for activities that
    /// actually track it via GPS.
    func saveSport(_ activity: SportActivity,
                   startedAt: Date,
                   endedAt: Date,
                   movingSeconds: TimeInterval,
                   distanceMeters: Double,
                   calories: Int) {
        guard isAvailable else { return }
        let energy = HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories))
        let distance: HKQuantity? = (activity.usesGPS && distanceMeters > 0)
            ? HKQuantity(unit: .meter(), doubleValue: distanceMeters)
            : nil
        let workout = HKWorkout(activityType: activity.hkType,
                                start: startedAt,
                                end: endedAt,
                                duration: movingSeconds,
                                totalEnergyBurned: energy,
                                totalDistance: distance,
                                metadata: nil)
        hk.save(workout) { _, _ in }
    }

    // MARK: - Write: Nutrition

    func saveMealEntry(calories: Double, protein: Double, carbs: Double, fat: Double) {
        guard isAvailable else { return }
        let now = Date()
        var samples: [HKQuantitySample] = []

        func makeSample(_ id: HKQuantityTypeIdentifier, unit: HKUnit, value: Double) {
            guard value > 0, let type = HKQuantityType.quantityType(forIdentifier: id) else { return }
            samples.append(HKQuantitySample(type: type,
                                             quantity: HKQuantity(unit: unit, doubleValue: value),
                                             start: now, end: now))
        }

        makeSample(.dietaryEnergyConsumed,   unit: .kilocalorie(), value: calories)
        makeSample(.dietaryProtein,          unit: .gram(),         value: protein)
        makeSample(.dietaryCarbohydrates,    unit: .gram(),         value: carbs)
        makeSample(.dietaryFatTotal,         unit: .gram(),         value: fat)

        guard !samples.isEmpty else { return }
        hk.save(samples) { _, _ in }
    }

    // MARK: - Write: Water

    func saveWater(glasses: Int) {
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        let liters = Double(glasses) * 0.25
        let start  = Calendar.current.startOfDay(for: .now)
        let pred   = HKQuery.predicateForSamples(withStart: start, end: .now)

        hk.deleteObjects(of: type, predicate: pred) { [weak self] _, _, _ in
            guard let self, liters > 0 else { return }
            let sample = HKQuantitySample(type: type,
                                           quantity: HKQuantity(unit: .liter(), doubleValue: liters),
                                           start: start, end: .now)
            self.hk.save(sample) { _, _ in }
        }
    }

    // MARK: - Write: Body Mass

    func saveBodyMass(kg: Double) {
        guard isAvailable, kg > 0,
              let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let sample = HKQuantitySample(type: type,
                                       quantity: HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg),
                                       start: .now, end: .now)
        hk.save(sample) { _, _ in }
    }
}
