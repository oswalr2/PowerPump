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
    /// Last night's time asleep, in seconds. Zero when nothing was recorded —
    /// which is the normal case unless the user wears a watch or uses a
    /// sleep-tracking app, so the UI has to handle "no data" gracefully.
    @Published var sleepLastNight:    TimeInterval = 0

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
        // Recovery signals for the weekly coach review. Only an Apple Watch
        // records them; without one these just come back empty.
        .restingHeartRate,
        .heartRateVariabilitySDNN,
    ]

    private var shareTypes: Set<HKSampleType> {
        let qtypes = Self.writeIDs.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
        return Set(qtypes + [HKObjectType.workoutType()])
    }

    private var readTypes: Set<HKObjectType> {
        var types = Set(Self.readIDs.compactMap {
            HKQuantityType.quantityType(forIdentifier: $0) as HKObjectType?
        })
        // Sleep is a category type, not a quantity, so it can't ride along in
        // readIDs above.
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }

    private init() {
        guard isAvailable else { return }
        // HealthKit never reveals read permission, and authorizationStatus
        // only reports *write* access — for steps, which the app doesn't
        // write, it was never "authorized", so every relaunch lost the
        // connection. "Already asked" is the signal Apple provides.
        hk.getRequestStatusForAuthorization(toShare: shareTypes, read: readTypes) { [weak self] status, _ in
            guard let self else { return }
            switch status {
            case .unnecessary:
                DispatchQueue.main.async {
                    self.isAuthorized = true
                    self.fetchTodayStats()
                }
            case .shouldRequest where self.hasConnectedBefore:
                // An update added read types (sleep, resting HR, HRV), so the
                // status went back to "should request" for users who had
                // already connected. Ask again — iOS only shows the new types —
                // instead of silently showing them as disconnected.
                DispatchQueue.main.async { self.requestAuthorization() }
            default:
                break
            }
        }
    }

    private static let connectedOnceKey = "hk_connected_once"

    /// Whether the user has gone through the HealthKit sheet before. Users
    /// who connected before the flag existed are recognised by the write
    /// types: their status is no longer `.notDetermined` once asked.
    private var hasConnectedBefore: Bool {
        if UserDefaults.standard.bool(forKey: Self.connectedOnceKey) { return true }
        return shareTypes.contains { hk.authorizationStatus(for: $0) != .notDetermined }
    }

    /// Time asleep in a set of samples, counting overlaps once. The watch
    /// and a sleep app often record the same night, and adding both up
    /// reported 16-hour nights.
    static func asleepSeconds(_ samples: [HKCategorySample]) -> TimeInterval {
        let asleep: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
        ]
        let spans = samples.filter { asleep.contains($0.value) }
            .map { ($0.startDate, $0.endDate) }.sorted { $0.0 < $1.0 }
        var total: TimeInterval = 0
        var current: (Date, Date)?
        for span in spans {
            if let c = current, span.0 <= c.1 {
                current = (c.0, max(c.1, span.1))
            } else {
                if let c = current { total += c.1.timeIntervalSince(c.0) }
                current = span
            }
        }
        if let c = current { total += c.1.timeIntervalSince(c.0) }
        return total
    }

    // MARK: - Authorization

    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        guard isAvailable else { completion(false); return }
        hk.requestAuthorization(toShare: shareTypes, read: readTypes) { [weak self] ok, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = ok
                if ok {
                    UserDefaults.standard.set(true, forKey: Self.connectedOnceKey)
                    self?.fetchTodayStats()
                }
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
        fetchLastNightSleep()
    }

    /// Total time actually asleep last night.
    ///
    /// The window starts at 6pm yesterday so a normal bedtime falls inside it,
    /// and only the "asleep" states count — `inBed` would include lying awake
    /// reading, which would flatter the number.
    func fetchLastNightSleep() {
        guard isAvailable,
              let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let cal = Calendar.current
        let start = cal.date(byAdding: .hour, value: -6,
                             to: cal.startOfDay(for: .now)) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        let query = HKSampleQuery(sampleType: type, predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { [weak self] _, samples, _ in
            let total = Self.asleepSeconds(samples as? [HKCategorySample] ?? [])
            DispatchQueue.main.async { self?.sleepLastNight = total }
        }
        hk.execute(query)
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
                // An old scale reading mustn't overwrite a newer weigh-in
                // logged in the app.
                if let latest = ProgressStore.shared.weightEntries.last?.date, latest > date { return }
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

    // MARK: - Daily history (coach weekly review)

    typealias DailyHistory = HealthDailyHistory

    /// Reads the series the weekly review needs. Four queries in parallel;
    /// the completion runs on the main queue once all of them are back.
    func fetchDailyHistory(days: Int, completion: @escaping (DailyHistory) -> Void) {
        guard isAvailable else { completion(DailyHistory()); return }
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: .now)) ?? .now
        var result = DailyHistory()
        let lock = NSLock()
        let group = DispatchGroup()

        func collection(_ id: HKQuantityTypeIdentifier, _ option: HKStatisticsOptions, unit: HKUnit,
                        store: @escaping (inout DailyHistory, [Date: Double]) -> Void) {
            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return }
            group.enter()
            let q = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: .now),
                options: option, anchorDate: start, intervalComponents: DateComponents(day: 1))
            q.initialResultsHandler = { _, results, _ in
                var values: [Date: Double] = [:]
                results?.enumerateStatistics(from: start, to: .now) { stat, _ in
                    let qty = option == .cumulativeSum ? stat.sumQuantity() : stat.averageQuantity()
                    if let v = qty?.doubleValue(for: unit), v > 0 {
                        values[cal.startOfDay(for: stat.startDate)] = v
                    }
                }
                lock.lock(); store(&result, values); lock.unlock()
                group.leave()
            }
            hk.execute(q)
        }

        collection(.stepCount, .cumulativeSum, unit: .count()) { $0.steps = $1 }
        collection(.restingHeartRate, .discreteAverage, unit: HKUnit(from: "count/min")) { $0.restingHR = $1 }
        collection(.heartRateVariabilitySDNN, .discreteAverage, unit: .secondUnit(with: .milli)) { $0.hrv = $1 }

        // Sleep: asleep time per night, credited to the day the night ends.
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            group.enter()
            let asleep: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            ]
            let q = HKSampleQuery(sampleType: sleepType,
                                  predicate: HKQuery.predicateForSamples(withStart: start, end: .now),
                                  limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let byNight = Dictionary(grouping: (samples as? [HKCategorySample] ?? [])
                    .filter { asleep.contains($0.value) }) { cal.startOfDay(for: $0.endDate) }
                var nights: [Date: Double] = [:]
                for (day, group) in byNight { nights[day] = Self.asleepSeconds(group) / 3600 }
                lock.lock(); result.sleepHours = nights; lock.unlock()
                group.leave()
            }
            hk.execute(q)
        }

        group.notify(queue: .main) { completion(result) }
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
