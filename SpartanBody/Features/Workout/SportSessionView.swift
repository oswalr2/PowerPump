import SwiftUI
import MapKit
import CoreLocation

/// Generic active-session view for any sport. Outdoor sports get a live
/// map + distance; indoor sports show only the timer. Finishing saves the
/// session to HealthKit + our internal history.
struct SportSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var location = LocationService.shared

    let sport: SportActivity

    @State private var startedAt: Date?
    @State private var pausedAccum: TimeInterval = 0
    @State private var pauseStartedAt: Date?
    @State private var isPaused = false
    @State private var didStart = false
    @State private var elapsed: TimeInterval = 0
    @State private var distance: Double = 0           // meters
    @State private var route: [CLLocationCoordinate2D] = []
    @State private var lastLocation: CLLocation?
    @State private var showFinishConfirm = false
    @State private var timer: Timer?
    @State private var locationSubscription: Any?
    @State private var finishedRecord: SportSessionRecord?

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
            }

            statsPanel
        }
        .onAppear { setupLocationIfNeeded() }
        .onDisappear { stopTimer() }
        .onChange(of: location.authorizationStatus) { _ in setupLocationIfNeeded() }
        .alert(LocalizedStringKey("Finish session?"), isPresented: $showFinishConfirm) {
            Button(LocalizedStringKey("Discard"), role: .destructive) { discardAndDismiss() }
            Button(LocalizedStringKey("Save")) { saveAndShowSummary() }
            Button(LocalizedStringKey("Cancel"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey("Save this session to your history and Apple Health?"))
        }
        .fullScreenCover(item: $finishedRecord, onDismiss: { dismiss() }) { _ in
            SportSummaryView(sport: sport,
                             elapsed: elapsed,
                             distance: distance,
                             route: route,
                             calories: estimatedCalories)
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        if sport.usesGPS {
            ZStack {
                SportMapView(routeCoordinates: route,
                             userLocation: lastLocation?.coordinate)
                LinearGradient(
                    colors: [.black.opacity(0.45), .clear,
                             .black.opacity(0.4), .black.opacity(0.8)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        } else {
            LinearGradient(
                colors: [Color.sbAccent.opacity(0.15), Color.sbBackground],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                if didStart { showFinishConfirm = true } else { dismiss() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(sport.usesGPS ? .white : .sbTextPrimary)
                    .frame(width: 38, height: 38)
                    .background(sport.usesGPS ? Color.black.opacity(0.55) : Color.sbSurface)
                    .clipShape(Circle())
            }
            Spacer()
            VStack(spacing: 2) {
                Text(LocalizedStringKey(sport.nameKey))
                    .font(SBFont.heading(15))
                    .foregroundColor(sport.usesGPS ? .white : .sbTextPrimary)
                if sport.usesGPS {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill").font(.system(size: 9))
                        Text(LocalizedStringKey("GPS"))
                            .font(SBFont.label(9))
                    }
                    .foregroundColor(.white.opacity(0.85))
                }
            }
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Stats panel

    private var statsPanel: some View {
        VStack(spacing: 16) {
            if sport.usesGPS && location.authorizationStatus == .notDetermined {
                requestLocationPrompt
            } else {
                bigStats
                controlsRow
            }
        }
        .padding(20)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var requestLocationPrompt: some View {
        VStack(spacing: 10) {
            Text(LocalizedStringKey("Location access needed"))
                .font(SBFont.heading(15))
                .foregroundColor(.sbTextPrimary)
            Text(LocalizedStringKey("PowerPump uses your location to trace your route and measure distance."))
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
            SBPrimaryButton(title: "Allow Location") { location.requestAuthorization() }
        }
    }

    private var bigStats: some View {
        VStack(spacing: 12) {
            Text(formattedTime)
                .font(SBFont.display(56))
                .foregroundColor(.sbTextPrimary)
                .monospacedDigit()

            HStack(spacing: 0) {
                if sport.usesGPS {
                    statCell(value: String(format: "%.2f", distance / 1000), unit: "km", label: "Distance")
                    Divider().frame(height: 36)
                }
                statCell(value: "\(estimatedCalories)", unit: "kcal", label: "Burned")
            }
        }
    }

    private func statCell(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(SBFont.heading(20))
                    .foregroundColor(.sbTextPrimary)
                    .monospacedDigit()
                Text(unit)
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
            }
            Text(LocalizedStringKey(label))
                .font(SBFont.label(9))
                .foregroundColor(.sbTextSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var controlsRow: some View {
        HStack(spacing: 16) {
            if !didStart {
                Button {
                    HapticManager.medium()
                    startSession()
                } label: {
                    Label(LocalizedStringKey("Start"), systemImage: "play.fill")
                        .font(SBFont.heading(16))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.sbAccent)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    HapticManager.light()
                    if isPaused { resume() } else { pause() }
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.sbTextPrimary)
                        .frame(width: 56, height: 56)
                        .background(Color.sbSurfaceRaised)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    HapticManager.medium()
                    showFinishConfirm = true
                } label: {
                    Label(LocalizedStringKey("Finish"), systemImage: "stop.fill")
                        .font(SBFont.heading(16))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.sbRed)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Lifecycle

    private func setupLocationIfNeeded() {
        guard sport.usesGPS else { return }
        if location.authorizationStatus == .authorizedWhenInUse
            || location.authorizationStatus == .authorizedAlways {
            location.startTracking()
            // Subscribe to location updates.
            locationSubscription = location.locationPublisher.sink { loc in
                handle(location: loc)
            }
        }
    }

    private func startSession() {
        startedAt = Date()
        didStart = true
        isPaused = false
        startTimer()
    }

    private func pause() {
        isPaused = true
        pauseStartedAt = Date()
    }

    private func resume() {
        if let p = pauseStartedAt {
            pausedAccum += Date().timeIntervalSince(p)
        }
        pauseStartedAt = nil
        isPaused = false
    }

    private func discardAndDismiss() {
        stopTimer()
        location.stopTracking()
        dismiss()
    }

    private func saveAndShowSummary() {
        stopTimer()
        location.stopTracking()
        guard let start = startedAt else { dismiss(); return }
        let end = Date()
        let record = SportSessionRecord(
            sportId: sport.id,
            startedAt: start,
            endedAt: end,
            movingSeconds: elapsed,
            distanceMeters: distance,
            calories: estimatedCalories,
            route: route.map { RunRoutePoint(latitude: $0.latitude,
                                             longitude: $0.longitude,
                                             timestamp: Date()) }
        )
        SportSessionStore.shared.add(record)
        HealthKitService.shared.saveSport(
            sport,
            startedAt: start,
            endedAt: end,
            movingSeconds: elapsed,
            distanceMeters: distance,
            calories: estimatedCalories
        )
        finishedRecord = record
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in tick() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @MainActor
    private func tick() {
        guard let start = startedAt, !isPaused else { return }
        elapsed = Date().timeIntervalSince(start) - pausedAccum
    }

    // MARK: - Location handling

    private func handle(location new: CLLocation) {
        guard sport.usesGPS, !isPaused, didStart else { return }
        let coord = new.coordinate
        if let prev = lastLocation {
            let delta = new.distance(from: prev)
            // Same anti-jitter rule as RunStore.
            if delta > 3 && delta < 200 {
                distance += delta
                route.append(coord)
            }
        } else {
            route.append(coord)
        }
        lastLocation = new
    }

    // MARK: - Derived

    private var estimatedCalories: Int {
        Int(elapsed / 60 * sport.kcalPerMinute)
    }

    private var formattedTime: String {
        let t = Int(elapsed)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}

// MARK: - Sport map (UIKit wrapper, iOS 16 compatible)

private struct SportMapView: UIViewRepresentable {
    let routeCoordinates: [CLLocationCoordinate2D]
    let userLocation: CLLocationCoordinate2D?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        map.isPitchEnabled = false
        map.isRotateEnabled = true
        map.delegate = context.coordinator
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        if routeCoordinates.count >= 2 {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            map.addOverlay(polyline)
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKPolylineRenderer(polyline: line)
            renderer.strokeColor = UIColor(named: "AccentColor") ?? .systemBlue
            renderer.lineWidth = 5
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
    }
}

// MARK: - Summary

private struct SportSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let sport: SportActivity
    let elapsed: TimeInterval
    let distance: Double
    let route: [CLLocationCoordinate2D]
    let calories: Int

    var body: some View {
        ZStack {
            Color.sbBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                if sport.usesGPS && route.count >= 2 {
                    SportMapView(routeCoordinates: route, userLocation: nil)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
                Spacer(minLength: 16)
                statsBlock
                Spacer()
                doneButton
            }
        }
    }

    private var statsBlock: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: sport.icon)
                    .foregroundColor(.sbAccent)
                Text(LocalizedStringKey(sport.nameKey))
                    .font(SBFont.heading(20))
                    .foregroundColor(.sbTextPrimary)
            }

            HStack(spacing: 0) {
                cell(value: formattedTime, label: "Time")
                if sport.usesGPS {
                    Divider().frame(height: 52)
                    cell(value: String(format: "%.2f km", distance / 1000), label: "Distance")
                }
                Divider().frame(height: 52)
                cell(value: "\(calories) kcal", label: "Burned")
            }
            .padding(.horizontal, 24)
        }
    }

    private func cell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SBFont.display(24))
                .foregroundColor(.sbTextPrimary)
                .monospacedDigit()
            Text(LocalizedStringKey(label))
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var doneButton: some View {
        Button {
            HapticManager.light()
            dismiss()
        } label: {
            Text(LocalizedStringKey("Done"))
                .font(SBFont.heading(18))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.sbAccent)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
    }

    private var formattedTime: String {
        let t = Int(elapsed)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}
