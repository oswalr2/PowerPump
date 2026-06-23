import SwiftUI
import CoreLocation
import MapKit

/// Player for a single day of a structured running program. Runs through
/// the intervals in order, announces transitions, tracks GPS, and marks the
/// day complete when finished.
struct ProgramSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var location = LocationService.shared
    @ObservedObject private var coach    = RunningCoach.shared
    @ObservedObject private var run      = RunStore.shared
    @ObservedObject private var progress = RunProgramStore.shared

    let program: RunningProgram
    let weekNumber: Int
    let day: ProgramDay

    @State private var currentIndex = 0
    @State private var elapsedInCurrent: TimeInterval = 0
    @State private var totalElapsed: TimeInterval = 0
    @State private var isPaused = true
    @State private var didStart = false
    @State private var didAnnounceHalfway = false
    @State private var didCountdown3 = false
    @State private var didCountdown2 = false
    @State private var didCountdown1 = false
    @State private var didFinish = false
    @State private var showFinishConfirm = false
    @State private var timer: Timer?

    var body: some View {
        ZStack(alignment: .bottom) {
            mapBackground
                .ignoresSafeArea()

            // Dark overlay so stats are readable on top of the map.
            LinearGradient(
                colors: [.black.opacity(0.55), .black.opacity(0.25), .clear,
                         .black.opacity(0.4), .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
            }

            controlsPanel
        }
        .onAppear { ensureAuth() }
        .onDisappear { stopTimer() }
        .onChange(of: location.authorizationStatus) { _ in ensureAuth() }
        .alert(LocalizedStringKey("Finish session?"), isPresented: $showFinishConfirm) {
            Button(LocalizedStringKey("Discard"), role: .destructive) {
                cancelAndDismiss()
            }
            Button(LocalizedStringKey("Save")) {
                completeAndDismiss()
            }
            Button(LocalizedStringKey("Cancel"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey("Save your progress for this day?"))
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                if didStart && !didFinish { showFinishConfirm = true } else { dismiss() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            Spacer()
            VStack(spacing: 2) {
                Text(LocalizedStringKey(program.nameKey))
                    .font(SBFont.label(11))
                    .foregroundColor(.white.opacity(0.85))
                    .textCase(.uppercase)
                Text(String(format: NSLocalizedString("Week %lld · Day %lld", comment: ""),
                            weekNumber, day.dayNumber))
                    .font(SBFont.heading(15))
                    .foregroundColor(.white)
            }
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Background map

    private var mapBackground: some View {
        RunMapBackground(
            routeCoordinates: run.activeSession?.route.map(\.coordinate) ?? [],
            userLocation: location.lastLocation?.coordinate
        )
    }

    // MARK: - Controls panel

    private var controlsPanel: some View {
        VStack(spacing: 16) {
            switch location.authorizationStatus {
            case .notDetermined:
                permissionPrompt
            case .denied, .restricted:
                permissionBlocked
            default:
                if didFinish {
                    completionCard
                } else {
                    intervalCard
                    progressBar
                    statsRow
                    controlsRow
                }
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

    private var permissionPrompt: some View {
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

    private var permissionBlocked: some View {
        VStack(spacing: 8) {
            Text(LocalizedStringKey("Location is off"))
                .font(SBFont.heading(15))
                .foregroundColor(.sbTextPrimary)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text(LocalizedStringKey("Open Settings"))
                    .font(SBFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(.sbAccent)
            }
        }
    }

    private var current: ProgramInterval { day.intervals[currentIndex] }
    private var nextInterval: ProgramInterval? {
        currentIndex + 1 < day.intervals.count ? day.intervals[currentIndex + 1] : nil
    }
    private var remainingInCurrent: Int {
        max(0, current.duration - Int(elapsedInCurrent))
    }

    private var intervalCard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: current.kind.icon)
                    .font(.system(size: 18, weight: .bold))
                Text(LocalizedStringKey(current.kind.labelKey))
                    .font(SBFont.heading(18))
                    .textCase(.uppercase)
            }
            .foregroundColor(.sbAccent)

            Text(formattedRemaining)
                .font(SBFont.display(56))
                .foregroundColor(.sbTextPrimary)
                .monospacedDigit()

            if let next = nextInterval {
                HStack(spacing: 6) {
                    Text(LocalizedStringKey("Next"))
                        .foregroundColor(.sbTextSecondary)
                    Image(systemName: next.kind.icon)
                        .foregroundColor(.sbTextSecondary)
                    Text(LocalizedStringKey(next.kind.labelKey))
                        .foregroundColor(.sbTextPrimary)
                        .fontWeight(.semibold)
                    Text("· \(formatted(seconds: next.duration))")
                        .foregroundColor(.sbTextSecondary)
                }
                .font(SBFont.caption())
            }
        }
    }

    private var progressBar: some View {
        let fraction = day.totalSeconds == 0 ? 0 : Double(totalElapsed) / Double(day.totalSeconds)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.sbSurfaceRaised)
                Capsule()
                    .fill(LinearGradient(colors: [.sbAccent, .sbAccent.opacity(0.6)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 6)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCell(title: "Total", value: formattedTotal)
            Divider().frame(height: 36)
            statCell(title: "Km", value: formattedKm)
            Divider().frame(height: 36)
            statCell(title: "kcal", value: "\(run.activeSession?.calories ?? 0)")
        }
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(SBFont.heading(18))
                .foregroundColor(.sbTextPrimary)
                .monospacedDigit()
            Text(LocalizedStringKey(title))
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
                    if isPaused {
                        coach.announceResume()
                        isPaused = false
                        startTimer()
                    } else {
                        coach.announcePause()
                        isPaused = true
                        stopTimer()
                    }
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

    private var completionCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 38))
                .foregroundColor(.sbGreen)
            Text(LocalizedStringKey("Day complete!"))
                .font(SBFont.heading(20))
                .foregroundColor(.sbTextPrimary)
            Text(String(format: NSLocalizedString("You finished week %lld, day %lld.", comment: ""),
                        weekNumber, day.dayNumber))
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
            SBPrimaryButton(title: "Done") {
                dismiss()
            }
        }
    }

    // MARK: - Lifecycle

    private func ensureAuth() {
        if location.authorizationStatus == .notDetermined { return }
    }

    private func startSession() {
        didStart = true
        isPaused = false
        currentIndex = 0
        elapsedInCurrent = 0
        totalElapsed = 0
        location.startTracking()
        run.start(activity: .run)
        coach.announceInterval(current, isFirst: true)
        coach.cueIntervalChange()
        startTimer()
    }

    private func completeAndDismiss() {
        stopTimer()
        location.stopTracking()
        _ = run.finish()
        let globalDay = progress.globalDay(in: program,
                                           weekNumber: weekNumber,
                                           dayNumber: day.dayNumber)
        progress.markComplete(globalDay, in: program)
        coach.announceFinish()
        coach.cueFinish()
        dismiss()
    }

    private func cancelAndDismiss() {
        stopTimer()
        location.stopTracking()
        run.discard()
        dismiss()
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in tick(0.5) }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @MainActor
    private func tick(_ dt: TimeInterval) {
        guard didStart, !isPaused, !didFinish else { return }
        elapsedInCurrent += dt
        totalElapsed += dt

        let remaining = current.duration - Int(elapsedInCurrent)
        let half = current.duration / 2

        // Halfway announcement for intervals 60s or longer.
        if !didAnnounceHalfway && current.duration >= 60 && Int(elapsedInCurrent) >= half {
            didAnnounceHalfway = true
            coach.announceHalfway()
        }

        // Countdown ticks at 3, 2, 1.
        if !didCountdown3 && remaining == 3 { didCountdown3 = true; coach.cueCountdown() }
        if !didCountdown2 && remaining == 2 { didCountdown2 = true; coach.cueCountdown() }
        if !didCountdown1 && remaining == 1 { didCountdown1 = true; coach.cueCountdown() }

        if remaining <= 0 { advanceInterval() }
    }

    private func advanceInterval() {
        if currentIndex + 1 < day.intervals.count {
            currentIndex += 1
            elapsedInCurrent = 0
            didAnnounceHalfway = false
            didCountdown3 = false
            didCountdown2 = false
            didCountdown1 = false
            coach.announceInterval(current, isFirst: false)
            coach.cueIntervalChange()
        } else {
            // Session finished cleanly.
            stopTimer()
            didFinish = true
            location.stopTracking()
            _ = run.finish()
            let globalDay = progress.globalDay(in: program,
                                               weekNumber: weekNumber,
                                               dayNumber: day.dayNumber)
            progress.markComplete(globalDay, in: program)
            coach.announceFinish()
            coach.cueFinish()
        }
    }

    // MARK: - Formatting

    private var formattedRemaining: String {
        formatted(seconds: remainingInCurrent)
    }

    private var formattedTotal: String {
        formatted(seconds: Int(totalElapsed))
    }

    private var formattedKm: String {
        String(format: "%.2f", run.activeSession?.distanceKm ?? 0)
    }

    private func formatted(seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Background map (no follow camera, just visual context)

private struct RunMapBackground: UIViewRepresentable {
    let routeCoordinates: [CLLocationCoordinate2D]
    let userLocation: CLLocationCoordinate2D?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        map.isPitchEnabled = false
        map.isRotateEnabled = false
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

