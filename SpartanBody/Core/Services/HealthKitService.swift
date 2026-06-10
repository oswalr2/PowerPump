import HealthKit
import Foundation

final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    private let hk = HKHealthStore()

    @Published var isAvailable  = HKHealthStore.isHealthDataAvailable()
    @Published var isAuthorized = false
    @Published var stepsToday:        Int    = 0
    @Published var activeEnergyToday: Double = 0

    // MARK: - Types

    private static let writeIDs: [HKQuantityTypeIdentifier] = [
        .activeEnergyBurned,
        .dietaryEnergyConsumed,
        .dietaryProtein,
        .dietaryCarbohydrates,
        .dietaryFatTotal,
        .dietaryWater,
        .bodyMass,
    ]

    private static let readIDs: [HKQuantityTypeIdentifier] = [
        .stepCount,
        .activeEnergyBurned,
        .bodyMass,
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
